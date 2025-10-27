defmodule PurseCraft.Accounting.Commands.Transactions.CreateTransfer do
  @moduledoc """
  Creates a transfer between two accounts.

  A transfer creates two linked transactions representing money movement:
  - Outflow transaction from source account (negative amount)
  - Inflow transaction to destination account (positive amount)

  Both transactions are linked bidirectionally via `linked_transaction_id` and have
  no budget impact (envelope_id: nil on all lines). The operation is atomic - either
  both transactions are created or the entire operation rolls back.

  ## Examples

      # Transfer between accounts
      iex> CreateTransfer.call(scope, workspace, %{
      ...>   from_account: %Account{id: 1},
      ...>   to_account: %Account{id: 2},
      ...>   amount: 50000,
      ...>   memo: "Monthly savings"
      ...> })
      {:ok, {%Transaction{amount: -50000}, %Transaction{amount: 50000}}}

      # Using external IDs
      iex> CreateTransfer.call(scope, workspace, %{
      ...>   from_account: "account-uuid-1",
      ...>   to_account: "account-uuid-2",
      ...>   amount: 25000,
      ...>   cleared: true
      ...> })
      {:ok, {%Transaction{cleared: true}, %Transaction{cleared: true}}}

  """

  alias PurseCraft.Accounting.Commands.Accounts.FetchAccount
  alias PurseCraft.Accounting.Policy
  alias PurseCraft.Accounting.Repositories.TransactionRepository
  alias PurseCraft.Accounting.Schemas.Account
  alias PurseCraft.Accounting.Schemas.Transaction
  alias PurseCraft.Core.Schemas.Workspace
  alias PurseCraft.Identity.Schemas.Scope
  alias PurseCraft.PubSub
  alias PurseCraft.Repo
  alias PurseCraft.Search.Workers.GenerateTokensWorker
  alias PurseCraft.Utilities

  @type account_ref :: Account.t() | integer() | Ecto.UUID.t()

  @type transfer_attrs :: %{
          required(:from_account) => account_ref(),
          required(:to_account) => account_ref(),
          required(:amount) => pos_integer(),
          optional(:memo) => String.t(),
          optional(:date) => Date.t(),
          optional(:cleared) => boolean()
        }

  @doc """
  Creates a transfer between two accounts with atomic transaction creation.

  The amount should always be positive - the command determines the correct
  signs for each transaction automatically.

  ## Parameters

  - `scope` - Authorization scope
  - `workspace` - Workspace containing both accounts
  - `attrs` - Transfer attributes including from/to accounts and amount

  ## Returns

  - `{:ok, {from_transaction, to_transaction}}` - Both linked transactions
  - `{:error, :unauthorized}` - User lacks permission
  - `{:error, :not_found}` - Account not found
  - `{:error, changeset}` - Validation error

  """
  @spec call(Scope.t(), Workspace.t(), transfer_attrs()) ::
          {:ok, {Transaction.t(), Transaction.t()}}
          | {:error, :unauthorized}
          | {:error, :not_found}
          | {:error, Ecto.Changeset.t()}
  def call(%Scope{} = scope, %Workspace{} = workspace, attrs) do
    with :ok <- Policy.authorize(:transaction_create, scope, %{workspace: workspace}),
         attrs = normalize_attrs(attrs, workspace),
         {:ok, from_account} <- fetch_account(scope, workspace, attrs.from_account),
         {:ok, to_account} <- fetch_account(scope, workspace, attrs.to_account),
         {:ok, {from_transaction, to_transaction}} <- create_transfer_transactions(attrs, from_account, to_account),
         :ok <- schedule_search_tokens(from_transaction, to_transaction, workspace, attrs),
         :ok <- broadcast_transactions(from_transaction, to_transaction, workspace) do
      {:ok, {from_transaction, to_transaction}}
    end
  end

  defp normalize_attrs(attrs, workspace) do
    attrs
    |> Utilities.atomize_keys()
    |> Map.put_new(:date, Date.utc_today())
    |> Map.put_new(:cleared, false)
    |> Map.put(:workspace_id, workspace.id)
  end

  defp fetch_account(scope, workspace, account_ref) do
    FetchAccount.call(scope, workspace, account_ref)
  end

  defp create_transfer_transactions(attrs, from_account, to_account) do
    Repo.transaction(fn ->
      with {:ok, from_transaction} <- create_from_transaction(attrs, from_account),
           {:ok, to_transaction} <- create_to_transaction(attrs, to_account),
           {:ok, _updated_from} <- link_transaction(from_transaction, to_transaction.id),
           {:ok, _updated_to} <- link_transaction(to_transaction, from_transaction.id) do
        # Reload both transactions to get the linked_transaction_id and transaction_lines
        # We call Repository.get_by_id directly here (within Repo.transaction) to reload
        # the just-created transactions with their updated linked_transaction_id values.
        # This is an exception to the Fetch* pattern since we're reloading within the same
        # transaction context and don't need authorization checks.
        # credo:disable-for-this-line
        from_transaction = TransactionRepository.get_by_id(from_transaction.id, preload: [:transaction_lines])
        # credo:disable-for-this-line
        to_transaction = TransactionRepository.get_by_id(to_transaction.id, preload: [:transaction_lines])

        {from_transaction, to_transaction}
      else
        {:error, reason} -> Repo.rollback(reason)
      end
    end)
  end

  defp create_from_transaction(attrs, from_account) do
    transaction_data = %{
      date: attrs.date,
      amount: -attrs.amount,
      account_id: from_account.id,
      workspace_id: attrs.workspace_id,
      memo: attrs[:memo],
      cleared: attrs.cleared,
      payee_id: nil,
      lines: [
        %{
          amount: -attrs.amount,
          envelope_id: nil,
          payee_id: nil
        }
      ]
    }

    TransactionRepository.create(transaction_data)
  end

  defp create_to_transaction(attrs, to_account) do
    transaction_data = %{
      date: attrs.date,
      amount: attrs.amount,
      account_id: to_account.id,
      workspace_id: attrs.workspace_id,
      memo: attrs[:memo],
      cleared: attrs.cleared,
      payee_id: nil,
      lines: [
        %{
          amount: attrs.amount,
          envelope_id: nil,
          payee_id: nil
        }
      ]
    }

    TransactionRepository.create(transaction_data)
  end

  defp link_transaction(transaction, linked_transaction_id) do
    TransactionRepository.update(transaction, %{linked_transaction_id: linked_transaction_id})
  end

  defp schedule_search_tokens(from_transaction, to_transaction, workspace, attrs) do
    if attrs[:memo] do
      schedule_search_token_generation(from_transaction, workspace)
      schedule_search_token_generation(to_transaction, workspace)
    end

    :ok
  end

  defp schedule_search_token_generation(transaction, workspace) do
    searchable_fields = Utilities.build_searchable_fields(transaction, [:memo])

    if map_size(searchable_fields) > 0 do
      %{
        "workspace_id" => workspace.id,
        "entity_type" => "transaction",
        "entity_id" => transaction.id,
        "searchable_fields" => searchable_fields
      }
      |> GenerateTokensWorker.new()
      |> Oban.insert()
    end
  end

  defp broadcast_transactions(from_transaction, to_transaction, workspace) do
    PubSub.broadcast_workspace(workspace, {:transaction_created, from_transaction})
    PubSub.broadcast_workspace(workspace, {:transaction_created, to_transaction})
    :ok
  end
end

defmodule PurseCraft.Accounting.Commands.Transactions.UpdateTransaction do
  @moduledoc """
  Updates an existing transaction.

  Allows updating memo, cleared status, payee, and transaction lines.
  Blocks changes to immutable fields (account_id, workspace_id, date, amount)
  to maintain audit trail integrity.

  When updating lines, validates that the sum of line amounts equals the transaction amount.
  Tracks old payees and schedules async cleanup for orphaned payees.
  """

  alias PurseCraft.Accounting.Policy
  alias PurseCraft.Accounting.Repositories.TransactionRepository
  alias PurseCraft.Accounting.Schemas.Transaction
  alias PurseCraft.Accounting.Workers.CleanupOrphanedPayeesWorker
  alias PurseCraft.Core.Schemas.Workspace
  alias PurseCraft.Identity.Schemas.Scope
  alias PurseCraft.PubSub
  alias PurseCraft.Search.Workers.GenerateTokensWorker
  alias PurseCraft.Utilities

  @immutable_fields [:account_id, :workspace_id, :date, :amount]

  @type update_attrs :: %{
          optional(:memo) => String.t(),
          optional(:cleared) => boolean(),
          optional(:payee_id) => integer() | nil,
          optional(:lines) => [line_attrs()]
        }

  @type line_attrs :: %{
          required(:amount) => integer(),
          optional(:envelope_id) => integer() | nil,
          optional(:payee_id) => integer() | nil,
          optional(:memo) => String.t()
        }

  @doc """
  Updates a transaction with the given attributes.

  Only allows updating memo, cleared status, payee_id, and lines.
  Immutable fields (account_id, workspace_id, date, amount) are blocked
  and will return an error if present in attrs.

  When updating lines, validates that sum(lines.amount) == transaction.amount.

  ## Examples

      iex> UpdateTransaction.call(scope, workspace, "txn-uuid", %{memo: "Updated"})
      {:ok, %Transaction{}}

      iex> UpdateTransaction.call(scope, workspace, "txn-uuid", %{cleared: true})
      {:ok, %Transaction{}}

      iex> UpdateTransaction.call(scope, workspace, "txn-uuid", %{
      ...>   lines: [%{amount: 5000, envelope_id: 3}]
      ...> })
      {:ok, %Transaction{}}

      iex> UpdateTransaction.call(scope, workspace, "invalid-uuid", %{memo: "Test"})
      {:error, :not_found}

      iex> UpdateTransaction.call(unauthorized_scope, workspace, "txn-uuid", %{memo: "Test"})
      {:error, :unauthorized}

  """
  @spec call(Scope.t(), Workspace.t(), String.t(), update_attrs()) ::
          {:ok, Transaction.t()}
          | {:error, :not_found}
          | {:error, :unauthorized}
          | {:error, :immutable_field}
          | {:error, :amount_mismatch}
          | {:error, Ecto.Changeset.t()}
  def call(%Scope{} = scope, %Workspace{} = workspace, transaction_external_id, attrs) do
    attrs = Utilities.atomize_keys(attrs)

    with {:ok, transaction} <- fetch_transaction(workspace, transaction_external_id),
         :ok <- Policy.authorize(:transaction_update, scope, %{workspace: workspace}),
         :ok <- validate_no_immutable_fields(attrs),
         :ok <- validate_empty_lines(attrs),
         :ok <- validate_line_amounts(transaction, attrs),
         old_payee_ids = collect_old_payee_ids(transaction, attrs),
         {:ok, updated_transaction} <- perform_update(transaction, attrs),
         :ok <- schedule_payee_cleanup(workspace, old_payee_ids),
         :ok <- schedule_search_token_generation(updated_transaction, workspace, attrs) do
      PubSub.broadcast_workspace(workspace, {:transaction_updated, updated_transaction})
      {:ok, updated_transaction}
    end
  end

  defp fetch_transaction(workspace, external_id) do
    case TransactionRepository.get_by_external_id(external_id, preload: [:transaction_lines]) do
      nil ->
        {:error, :not_found}

      transaction ->
        if transaction.workspace_id == workspace.id do
          {:ok, transaction}
        else
          {:error, :not_found}
        end
    end
  end

  defp validate_no_immutable_fields(attrs) do
    immutable_present = Enum.any?(@immutable_fields, &Map.has_key?(attrs, &1))

    if immutable_present do
      {:error, :immutable_field}
    else
      :ok
    end
  end

  defp validate_empty_lines(%{lines: []}), do: {:error, :empty_lines}
  defp validate_empty_lines(_attrs), do: :ok

  defp validate_line_amounts(transaction, %{lines: lines}) when is_list(lines) do
    line_sum = Enum.reduce(lines, 0, fn line, acc -> acc + line.amount end)

    if abs(line_sum) == abs(transaction.amount) do
      :ok
    else
      {:error, :amount_mismatch}
    end
  end

  defp validate_line_amounts(_transaction, _attrs), do: :ok

  defp collect_old_payee_ids(transaction, attrs) do
    transaction_payee_ids =
      if Map.has_key?(attrs, :payee_id) and attrs.payee_id != transaction.payee_id and
           transaction.payee_id != nil do
        [transaction.payee_id]
      else
        []
      end

    line_payee_ids =
      if Map.has_key?(attrs, :lines) do
        transaction.transaction_lines
        |> Enum.map(& &1.payee_id)
        |> Enum.reject(&is_nil/1)
      else
        []
      end

    Enum.uniq(transaction_payee_ids ++ line_payee_ids)
  end

  defp perform_update(transaction, %{lines: lines} = attrs) when is_list(lines) do
    transaction_attrs = Map.delete(attrs, :lines)

    TransactionRepository.update_with_lines(
      transaction,
      transaction_attrs,
      lines,
      preload: [:transaction_lines]
    )
  end

  defp perform_update(transaction, attrs) do
    TransactionRepository.update(transaction, attrs)
  end

  defp schedule_payee_cleanup(_workspace, []), do: :ok

  defp schedule_payee_cleanup(workspace, old_payee_ids) do
    Enum.each(old_payee_ids, fn _payee_id ->
      %{"workspace_id" => workspace.id}
      |> CleanupOrphanedPayeesWorker.new()
      |> Oban.insert()
    end)

    :ok
  end

  defp schedule_search_token_generation(transaction, workspace, attrs) do
    if Map.has_key?(attrs, :memo) do
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

    :ok
  end
end

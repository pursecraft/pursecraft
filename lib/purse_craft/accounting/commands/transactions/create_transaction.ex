defmodule PurseCraft.Accounting.Commands.Transactions.CreateTransaction do
  @moduledoc """
  Creates a transaction using intuitive source/destination/with semantics.

  Supports both simple transactions and split transactions with per-line payee overrides.
  The command automatically determines debit/credit amounts based on source and destination types.

  ## Interface

  - **source**: Where money comes from (%Account{}, %Payee{}, :ready_to_assign)
  - **destination**: Where money goes to (%Account{}, %Envelope{}, :ready_to_assign) 
  - **with**: Transaction context (%Payee{}, %Envelope{}, :ready_to_assign, nil)

  ## Examples

      # Regular expense: Account → Envelope, with Payee
      CreateTransaction.call(scope, workspace, %{
        source: %Account{id: 123, name: "Chase Checking"},
        destination: %Envelope{id: 456, name: "Groceries"},
        with: %Payee{id: 789, name: "Kroger"},
        amount: 5000,
        memo: "Weekly shopping"
      })

      # Income: Payee → Account, with Ready to Assign for budget impact
      CreateTransaction.call(scope, workspace, %{
        source: %Payee{id: 999, name: "Acme Corp"},
        destination: %Account{id: 123, name: "Chase Checking"},
        with: :ready_to_assign,
        amount: 300000,
        memo: "Salary"
      })

      # Account transfer: Account → Account, no third party
      CreateTransaction.call(scope, workspace, %{
        source: %Account{id: 123, name: "Chase Checking"},
        destination: %Account{id: 456, name: "Chase Savings"},
        with: nil,
        amount: 50000,
        memo: "Monthly savings"
      })

      # Budget allocation: Ready to Assign → Envelope
      CreateTransaction.call(scope, workspace, %{
        source: :ready_to_assign,
        destination: %Envelope{id: 456, name: "Groceries"},
        with: nil,
        amount: 10000,
        memo: "Budget allocation"
      })

      # Split transaction with payee override
      CreateTransaction.call(scope, workspace, %{
        source: %Account{id: 123, name: "Chase Checking"},
        with: %Payee{id: 789, name: "Target"},  # Default payee
        memo: "Shopping trip",
        lines: [
          %{destination: %Envelope{id: 456, name: "Groceries"}, amount: 6000, memo: "Food"},
          %{destination: %Envelope{id: 999, name: "Personal"}, with: %Payee{id: 888, name: "John"}, amount: 4000, memo: "Paid back friend"}
        ]
      })

  """

  alias PurseCraft.Accounting.Policy
  alias PurseCraft.Accounting.Repositories.TransactionRepository
  alias PurseCraft.Accounting.Schemas.Account
  alias PurseCraft.Accounting.Schemas.Payee
  alias PurseCraft.Accounting.Schemas.Transaction
  alias PurseCraft.Budgeting.Schemas.Envelope
  alias PurseCraft.Core.Schemas.Workspace
  alias PurseCraft.Identity.Schemas.Scope
  alias PurseCraft.PubSub
  alias PurseCraft.Search.Workers.GenerateTokensWorker
  alias PurseCraft.Utilities

  @type entity :: Account.t() | Envelope.t() | Payee.t() | :ready_to_assign | nil

  @type transaction_attrs :: %{
          required(:source) => entity(),
          optional(:destination) => entity(),
          optional(:with) => entity(),
          optional(:amount) => pos_integer(),
          optional(:memo) => String.t(),
          optional(:date) => Date.t(),
          optional(:lines) => [line_attrs()]
        }

  @type line_attrs :: %{
          required(:destination) => entity(),
          required(:amount) => pos_integer(),
          optional(:with) => entity(),
          optional(:memo) => String.t()
        }

  @doc """
  Creates a transaction with automatic double-entry handling.

  Accepts either simple format (source + destination) or split format (source + lines).
  All amounts are positive - the command determines debit/credit based on entity types.
  """
  @spec call(Scope.t(), Workspace.t(), transaction_attrs()) ::
          {:ok, Transaction.t()} | {:error, Ecto.Changeset.t()} | {:error, :unauthorized}
  def call(%Scope{} = scope, %Workspace{} = workspace, attrs) do
    with :ok <- Policy.authorize(:transaction_create, scope, %{workspace: workspace}),
         attrs = normalize_attrs(attrs, workspace),
         {:ok, transaction_data} <- build_transaction_data(attrs),
         {:ok, transaction} <- TransactionRepository.create(transaction_data) do
      schedule_search_token_generation(transaction, workspace)
      PubSub.broadcast_workspace(workspace, {:transaction_created, transaction})
      {:ok, transaction}
    end
  end

  defp normalize_attrs(attrs, workspace) do
    attrs
    |> Utilities.atomize_keys()
    |> Map.put_new(:date, Date.utc_today())
    |> Map.put(:workspace_id, workspace.id)
    |> normalize_to_lines()
  end

  # Convert simple transaction to lines format for consistent processing
  defp normalize_to_lines(%{lines: _lines} = attrs), do: attrs

  defp normalize_to_lines(%{destination: destination, amount: amount} = attrs) do
    line = %{
      destination: destination,
      amount: amount,
      # Inherit transaction-level 'with' if no line-level override
      with: attrs[:with]
    }

    attrs
    |> Map.delete(:destination)
    |> Map.delete(:amount)
    |> Map.put(:lines, [line])
  end

  defp build_transaction_data(attrs) do
    with {:ok, account_data} <- determine_account_impact(attrs),
         {:ok, lines_data} <- build_lines_data(attrs) do
      transaction_data = %{
        date: attrs.date,
        amount: account_data.amount,
        account_id: account_data.account_id,
        payee_id: determine_transaction_payee_id(attrs, account_data),
        workspace_id: attrs.workspace_id,
        memo: attrs[:memo],
        lines: lines_data
      }

      {:ok, transaction_data}
    end
  end

  # Determine which account is impacted and the sign of the impact
  defp determine_account_impact(%{source: %Account{id: account_id}, lines: lines}) do
    total_amount =
      lines
      |> Enum.map(& &1.amount)
      |> Enum.sum()

    {:ok, %{account_id: account_id, amount: -total_amount, type: :outflow}}
  end

  defp determine_account_impact(%{lines: [%{destination: %Account{id: account_id}, amount: amount}]}) do
    {:ok, %{account_id: account_id, amount: amount, type: :inflow}}
  end

  defp determine_account_impact(%{source: %Payee{}, lines: [%{destination: %Account{id: account_id}, amount: amount}]}) do
    {:ok, %{account_id: account_id, amount: amount, type: :inflow}}
  end

  defp determine_account_impact(_attrs) do
    {:error, "Cannot determine account impact - need either source account or destination account"}
  end

  # For transaction-level payee, use the payee from source or transaction-level 'with'
  defp determine_transaction_payee_id(%{source: %Payee{id: payee_id}}, _account_data), do: payee_id
  defp determine_transaction_payee_id(%{with: %Payee{id: payee_id}}, _account_data), do: payee_id
  defp determine_transaction_payee_id(_attrs, _account_data), do: nil

  defp build_lines_data(%{lines: lines, with: default_with}) do
    lines_data =
      Enum.map(lines, fn line ->
        # Line-level 'with' overrides transaction-level 'with'
        line_with = Map.get(line, :with, default_with)

        %{
          amount: determine_line_amount(line),
          envelope_id: determine_envelope_id(line.destination),
          payee_id: determine_line_payee_id(line_with),
          memo: line[:memo]
        }
      end)

    {:ok, lines_data}
  end

  defp build_lines_data(%{lines: lines}) do
    build_lines_data(%{lines: lines, with: nil})
  end

  # Line amounts represent the positive amount flowing TO the destination
  defp determine_line_amount(%{amount: amount}), do: amount

  defp determine_envelope_id(%Envelope{id: id}), do: id
  defp determine_envelope_id(:ready_to_assign), do: nil
  defp determine_envelope_id(_other), do: nil

  defp determine_line_payee_id(%Payee{id: id}), do: id
  defp determine_line_payee_id(_other), do: nil

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
end

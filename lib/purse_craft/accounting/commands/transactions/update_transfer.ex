defmodule PurseCraft.Accounting.Commands.Transactions.UpdateTransfer do
  @moduledoc """
  Updates both sides of a transfer synchronously.

  Allows updating memo, cleared status, amount, and date. Changes to amount
  are applied to both sides of the transfer with correct signs (negative for
  outflow, positive for inflow). Account and workspace changes are silently
  ignored by the repository to maintain transfer integrity.

  Both sides of the transfer are updated atomically - either both succeed or
  both rollback. Search tokens are regenerated if memo changes, and PubSub
  events are broadcast for both transactions.

  ## Examples

      iex> call(scope, workspace, "txn-uuid", %{memo: "Rent payment"})
      {:ok, {%Transaction{memo: "Rent payment"}, %Transaction{memo: "Rent payment"}}}

      iex> call(scope, workspace, "txn-uuid", %{cleared: true})
      {:ok, {%Transaction{cleared: true}, %Transaction{cleared: true}}}

      iex> call(scope, workspace, "txn-uuid", %{amount: 50000})
      {:ok, {%Transaction{amount: -50000}, %Transaction{amount: 50000}}}

  ## Errors

  - `{:error, :not_found}` - Transaction doesn't exist or linked transaction missing
  - `{:error, :unauthorized}` - User lacks editor/owner permission
  - `{:error, :not_a_transfer}` - Transaction is not part of a transfer
  """

  alias PurseCraft.Accounting.Commands.Transactions.FetchTransaction
  alias PurseCraft.Accounting.Domain.AccountingRules
  alias PurseCraft.Accounting.Policy
  alias PurseCraft.Accounting.Repositories.TransactionRepository
  alias PurseCraft.Accounting.Schemas.Transaction
  alias PurseCraft.Core.Schemas.Workspace
  alias PurseCraft.Identity.Schemas.Scope
  alias PurseCraft.PubSub
  alias PurseCraft.Repo
  alias PurseCraft.Search.Workers.GenerateTokensWorker
  alias PurseCraft.Utilities

  @type transaction_ref :: Transaction.t() | integer() | Ecto.UUID.t()

  @type update_attrs :: %{
          optional(:memo) => String.t() | nil,
          optional(:cleared) => boolean(),
          optional(:amount) => pos_integer(),
          optional(:date) => Date.t()
        }

  @spec call(Scope.t(), Workspace.t(), transaction_ref(), update_attrs()) ::
          {:ok, {Transaction.t(), Transaction.t()}}
          | {:error, :not_found | :unauthorized | :not_a_transfer}

  def call(scope, workspace, transaction_ref, attrs) do
    with :ok <- Policy.authorize(:transaction_update, scope, %{workspace: workspace}),
         normalized_attrs = Utilities.atomize_keys(attrs),
         {:ok, transaction} <- FetchTransaction.call(scope, workspace, transaction_ref, preload: [:account]),
         :ok <- validate_is_transfer(transaction),
         {:ok, linked_transaction} <-
           fetch_linked_transaction(scope, workspace, transaction),
         {:ok, {updated_transaction, updated_linked}} <-
           update_both_transactions(scope, workspace, transaction, linked_transaction, normalized_attrs),
         :ok <- maybe_schedule_search_tokens(transaction, updated_transaction, updated_linked, workspace),
         :ok <- broadcast_updates(workspace, updated_transaction, updated_linked) do
      {:ok, {updated_transaction, updated_linked}}
    end
  end

  defp validate_is_transfer(%Transaction{linked_transaction_id: nil}), do: {:error, :not_a_transfer}

  defp validate_is_transfer(%Transaction{}), do: :ok

  defp fetch_linked_transaction(scope, workspace, %Transaction{linked_transaction_id: id}) do
    FetchTransaction.call(scope, workspace, id, preload: [:transaction_lines, :account])
  end

  defp update_both_transactions(scope, workspace, transaction, linked_transaction, attrs) do
    Repo.transaction(fn ->
      transaction_attrs = prepare_attrs_for_transaction(attrs, transaction)
      linked_attrs = prepare_attrs_for_transaction(attrs, linked_transaction)

      with {:ok, _updated_transaction} <- update_transaction_and_lines(transaction, transaction_attrs),
           {:ok, _updated_linked} <- update_transaction_and_lines(linked_transaction, linked_attrs),
           {:ok, reloaded_transaction} <-
             FetchTransaction.call(scope, workspace, transaction.id, preload: [:transaction_lines]),
           {:ok, reloaded_linked} <-
             FetchTransaction.call(scope, workspace, linked_transaction.id, preload: [:transaction_lines]) do
        {reloaded_transaction, reloaded_linked}
      else
        {:error, reason} -> Repo.rollback(reason)
      end
    end)
  end

  defp prepare_attrs_for_transaction(attrs, transaction) do
    case Map.get(attrs, :amount) do
      nil ->
        attrs

      amount when amount > 0 ->
        direction = AccountingRules.infer_transfer_direction(transaction)
        signed_amount = AccountingRules.transfer_amount(transaction.account, amount, direction)
        Map.put(attrs, :amount, signed_amount)
    end
  end

  defp update_transaction_and_lines(transaction, attrs) do
    case Map.get(attrs, :amount) do
      nil ->
        TransactionRepository.update(transaction, attrs)

      amount when is_integer(amount) ->
        line_attrs = [%{amount: amount}]
        TransactionRepository.update_with_lines(transaction, attrs, line_attrs)
    end
  end

  defp maybe_schedule_search_tokens(old_transaction, new_transaction, new_linked, workspace) do
    if old_transaction.memo != new_transaction.memo do
      schedule_search_token_generation(new_transaction, workspace)
      schedule_search_token_generation(new_linked, workspace)
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

    :ok
  end

  defp broadcast_updates(workspace, transaction, linked_transaction) do
    PubSub.broadcast_workspace(workspace, {:transaction_updated, transaction})
    PubSub.broadcast_workspace(workspace, {:transaction_updated, linked_transaction})
    :ok
  end
end

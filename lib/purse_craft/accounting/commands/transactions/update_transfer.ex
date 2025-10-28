defmodule PurseCraft.Accounting.Commands.Transactions.UpdateTransfer do
  @moduledoc """
  Updates both sides of a transfer synchronously.

  Only allows updating memo and cleared status to maintain transfer integrity.
  Amount, date, and account changes are blocked.

  Both sides of the transfer are updated atomically - either both succeed or
  both rollback. Search tokens are regenerated if memo changes, and PubSub
  events are broadcast for both transactions.

  ## Examples

      iex> call(scope, workspace, "txn-uuid", %{memo: "Rent payment"})
      {:ok, {%Transaction{memo: "Rent payment"}, %Transaction{memo: "Rent payment"}}}

      iex> call(scope, workspace, "txn-uuid", %{cleared: true})
      {:ok, {%Transaction{cleared: true}, %Transaction{cleared: true}}}

      iex> call(scope, workspace, "txn-uuid", %{amount: 50000})
      {:error, {:immutable_field, :amount}}

  ## Errors

  - `{:error, :not_found}` - Transaction doesn't exist or linked transaction missing
  - `{:error, :unauthorized}` - User lacks editor/owner permission
  - `{:error, :not_a_transfer}` - Transaction is not part of a transfer
  - `{:error, {:immutable_field, field}}` - Attempted to change blocked field
  """

  alias PurseCraft.Accounting.Commands.Transactions.FetchTransaction
  alias PurseCraft.Accounting.Policy
  alias PurseCraft.Accounting.Repositories.TransactionRepository
  alias PurseCraft.Accounting.Schemas.Transaction
  alias PurseCraft.Core.Schemas.Workspace
  alias PurseCraft.Identity.Schemas.Scope
  alias PurseCraft.PubSub
  alias PurseCraft.Repo
  alias PurseCraft.Search.Workers.GenerateTokensWorker
  alias PurseCraft.Utilities

  @immutable_fields [:amount, :date, :account_id, :workspace_id]

  @type update_attrs :: %{
          optional(:memo) => String.t() | nil,
          optional(:cleared) => boolean()
        }

  @spec call(
          Scope.t(),
          Workspace.t(),
          Transaction.t() | integer() | String.t(),
          update_attrs()
        ) ::
          {:ok, {Transaction.t(), Transaction.t()}}
          | {:error, :not_found | :unauthorized | :not_a_transfer | {:immutable_field, atom()}}

  def call(scope, workspace, transaction_ref, attrs) do
    with :ok <- Policy.authorize(:transaction_update, scope, %{workspace: workspace}),
         normalized_attrs = normalize_attrs(attrs),
         :ok <- validate_no_immutable_fields(normalized_attrs),
         {:ok, transaction} <- FetchTransaction.call(scope, workspace, transaction_ref),
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

  # Private functions

  defp normalize_attrs(attrs) do
    attrs
    |> Map.new(fn {k, v} -> {to_existing_atom_or_string(k), v} end)
    |> Map.new()
  end

  defp validate_no_immutable_fields(attrs) do
    invalid =
      attrs
      |> Map.keys()
      |> Enum.filter(&(&1 in @immutable_fields))

    if invalid == [] do
      :ok
    else
      {:error, {:immutable_field, Enum.at(invalid, 0)}}
    end
  end

  defp validate_is_transfer(%Transaction{linked_transaction_id: nil}), do: {:error, :not_a_transfer}

  defp validate_is_transfer(%Transaction{}), do: :ok

  defp fetch_linked_transaction(scope, workspace, %Transaction{linked_transaction_id: id}) do
    FetchTransaction.call(scope, workspace, id, preload: [:transaction_lines])
  end

  defp update_both_transactions(scope, workspace, transaction, linked_transaction, attrs) do
    Repo.transaction(fn ->
      with {:ok, _updated_transaction} <- TransactionRepository.update(transaction, attrs),
           {:ok, _updated_linked} <- TransactionRepository.update(linked_transaction, attrs),
           # Authorization is cached from the initial call, so this is efficient
           {:ok, reloaded_transaction} <-
             FetchTransaction.call(scope, workspace, transaction.id, preload: [:transaction_lines]),
           {:ok, reloaded_linked} <-
             FetchTransaction.call(scope, workspace, linked_transaction.id, preload: [:transaction_lines]) do
        {reloaded_transaction, reloaded_linked}
      else
        # coveralls-ignore-next-line
        {:error, reason} -> Repo.rollback(reason)
      end
    end)
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
        "entity_type" => "Transaction",
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

  defp to_existing_atom_or_string(key) when is_binary(key) do
    String.to_existing_atom(key)
  rescue
    # coveralls-ignore-next-line
    ArgumentError -> key
  end

  defp to_existing_atom_or_string(key), do: key
end

defmodule PurseCraft.Accounting.Commands.Transactions.DeleteTransaction do
  @moduledoc """
  Deletes a transaction with proper cleanup of orphaned payees and search tokens.

  Transaction lines are automatically cascade-deleted via database constraint.
  Schedules async cleanup for potentially orphaned payees and search tokens.
  """

  alias PurseCraft.Accounting.Policy
  alias PurseCraft.Accounting.Repositories.TransactionRepository
  alias PurseCraft.Accounting.Schemas.Transaction
  alias PurseCraft.Accounting.Workers.CleanupOrphanedPayeesWorker
  alias PurseCraft.Core.Schemas.Workspace
  alias PurseCraft.Identity.Schemas.Scope
  alias PurseCraft.PubSub
  alias PurseCraft.Search.Workers.DeleteTokensWorker

  @doc """
  Deletes a transaction from the workspace.

  Transaction lines are automatically cascade-deleted.
  Schedules cleanup for orphaned payees and search tokens.

  ## Examples

      iex> DeleteTransaction.call(scope, workspace, "txn-uuid")
      {:ok, %Transaction{}}

      iex> DeleteTransaction.call(scope, workspace, "invalid")
      {:error, :not_found}

      iex> DeleteTransaction.call(unauthorized_scope, workspace, "txn-uuid")
      {:error, :unauthorized}

  """
  @spec call(Scope.t(), Workspace.t(), String.t()) ::
          {:ok, Transaction.t()}
          | {:error, :not_found}
          | {:error, :unauthorized}
          | {:error, Ecto.Changeset.t()}
  def call(%Scope{} = scope, %Workspace{} = workspace, transaction_external_id) do
    with {:ok, transaction} <-
           TransactionRepository.fetch_by_external_id(workspace.id, transaction_external_id,
             preload: [:transaction_lines]
           ),
         :ok <- Policy.authorize(:transaction_delete, scope, %{workspace: workspace}),
         payee_ids = collect_payee_ids(transaction),
         {:ok, deleted_transaction} <- TransactionRepository.delete(transaction),
         :ok <- schedule_payee_cleanup(workspace, payee_ids),
         :ok <- schedule_search_token_deletion(deleted_transaction) do
      PubSub.broadcast_workspace(workspace, {:transaction_deleted, deleted_transaction})
      {:ok, deleted_transaction}
    end
  end

  defp collect_payee_ids(transaction) do
    transaction_payee_ids = if transaction.payee_id, do: [transaction.payee_id], else: []

    line_payee_ids =
      transaction.transaction_lines
      |> Enum.map(& &1.payee_id)
      |> Enum.reject(&is_nil/1)

    Enum.uniq(transaction_payee_ids ++ line_payee_ids)
  end

  defp schedule_payee_cleanup(_workspace, []), do: :ok

  defp schedule_payee_cleanup(workspace, payee_ids) do
    Enum.each(payee_ids, fn _payee_id ->
      %{"workspace_id" => workspace.id}
      |> CleanupOrphanedPayeesWorker.new()
      |> Oban.insert()
    end)

    :ok
  end

  defp schedule_search_token_deletion(transaction) do
    %{
      "entity_type" => "transaction",
      "entity_id" => transaction.id
    }
    |> DeleteTokensWorker.new()
    |> Oban.insert()

    :ok
  end
end

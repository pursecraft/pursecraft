defmodule PurseCraft.Accounting.Commands.Payees.CleanupOrphanedPayees do
  @moduledoc """
  Cleans up orphaned payees in a workspace.

  System maintenance command - no authorization required.
  Deletes payees that are no longer referenced by any transactions.
  """

  alias PurseCraft.Accounting.Queries.PayeeQuery
  alias PurseCraft.Accounting.Repositories.PayeeRepository
  alias PurseCraft.Core.Schemas.Workspace
  alias PurseCraft.Repo
  alias PurseCraft.Search.Workers.DeleteTokensWorker

  @doc """
  Deletes orphaned payees in a workspace.

  Accepts an optional list of payee IDs to filter the cleanup. If provided,
  only orphaned payees matching those IDs will be deleted. If empty, all
  orphaned payees in the workspace will be deleted.

  ## Examples

      iex> CleanupOrphanedPayees.call(workspace, [])
      {:ok, 3}

      iex> CleanupOrphanedPayees.call(workspace, [1, 2, 3])
      {:ok, 2}

  """
  @spec call(Workspace.t(), list(integer())) :: {:ok, non_neg_integer()}
  def call(%Workspace{} = workspace, payee_ids) when is_list(payee_ids) do
    {:ok, {count, deleted_payees}} =
      if payee_ids == [] do
        PayeeRepository.delete_orphaned(workspace)
      else
        delete_orphaned_by_ids(workspace, payee_ids)
      end

    schedule_search_token_deletion(deleted_payees)
    {:ok, count}
  end

  defp delete_orphaned_by_ids(workspace, payee_ids) do
    orphaned_payees =
      workspace.id
      |> PayeeQuery.by_workspace_id()
      |> PayeeQuery.orphaned()
      |> PayeeQuery.by_ids(payee_ids)
      |> Repo.all()

    payee_ids_to_delete = Enum.map(orphaned_payees, & &1.id)

    {count, _deleted} =
      workspace.id
      |> PayeeQuery.by_workspace_id()
      |> PayeeQuery.by_ids(payee_ids_to_delete)
      |> Repo.delete_all()

    {:ok, {count, orphaned_payees}}
  end

  defp schedule_search_token_deletion(payees) do
    Enum.each(payees, fn payee ->
      %{
        "entity_type" => "payee",
        "entity_id" => payee.id
      }
      |> DeleteTokensWorker.new()
      |> Oban.insert()
    end)
  end
end

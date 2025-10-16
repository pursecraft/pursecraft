defmodule PurseCraft.Accounting.Commands.Payees.CleanupOrphanedPayees do
  @moduledoc """
  Cleans up orphaned payees in a workspace.

  System maintenance command - no authorization required.
  Deletes payees that are no longer referenced by any transactions.
  """

  alias PurseCraft.Accounting.Repositories.PayeeRepository
  alias PurseCraft.Core.Schemas.Workspace
  alias PurseCraft.Search.Workers.DeleteTokensWorker

  @doc """
  Deletes all orphaned payees in a workspace.

  ## Examples

      iex> CleanupOrphanedPayees.call(workspace)
      {:ok, 3}

  """
  @spec call(Workspace.t()) :: {:ok, non_neg_integer()}
  def call(%Workspace{} = workspace) do
    {:ok, {count, deleted_payees}} = PayeeRepository.delete_orphaned(workspace)

    schedule_search_token_deletion(deleted_payees)
    {:ok, count}
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

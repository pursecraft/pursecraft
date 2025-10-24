defmodule PurseCraft.Accounting.Workers.CleanupOrphanedPayeesWorker do
  @moduledoc """
  Background worker for cleaning up orphaned payees.

  Processes cleanup jobs by calling the CleanupOrphanedPayees command.
  """

  use Oban.Worker, queue: :default

  alias PurseCraft.Accounting.Commands.Payees.CleanupOrphanedPayees
  alias PurseCraft.Core.Commands.Workspaces.FetchWorkspace

  @spec perform(Oban.Job.t()) :: :ok | {:error, term()}
  def perform(%Oban.Job{args: %{"workspace_id" => workspace_id}}) do
    with {:ok, workspace} <- FetchWorkspace.call(workspace_id),
         {:ok, _count} <- CleanupOrphanedPayees.call(workspace) do
      :ok
    end
  end
end

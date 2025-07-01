defmodule PurseCraft.Core.Commands.Workspaces.DeleteWorkspace do
  @moduledoc """
  Deletes a workspace.
  """

  alias PurseCraft.Core.Policy
  alias PurseCraft.Core.Repositories.WorkspaceRepository
  alias PurseCraft.Core.Schemas.Workspace
  alias PurseCraft.Identity.Schemas.Scope
  alias PurseCraft.PubSub

  @doc """
  Deletes a workspace.

  ## Examples

      iex> call(authorized_scope, workspace)
      {:ok, %Workspace{}}

      iex> call(unauthorized_scope, workspace)
      {:error, :unauthorized}

  """
  @spec call(Scope.t(), Workspace.t()) :: {:ok, Workspace.t()} | {:error, :unauthorized}
  def call(%Scope{} = scope, %Workspace{} = workspace) do
    with :ok <- Policy.authorize(:workspace_delete, scope, %{workspace: workspace}),
         {:ok, %Workspace{} = workspace} <- WorkspaceRepository.delete(workspace) do
      message = {:deleted, workspace}

      PubSub.broadcast_user_workspace(scope, message)
      PubSub.broadcast_workspace(workspace, message)

      {:ok, workspace}
    end
  end
end

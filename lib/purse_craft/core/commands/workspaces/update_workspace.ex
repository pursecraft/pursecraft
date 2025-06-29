defmodule PurseCraft.Core.Commands.Workspaces.UpdateWorkspace do
  @moduledoc """
  Updates a workspace.
  """

  alias PurseCraft.Core.Policy
  alias PurseCraft.Core.Repositories.WorkspaceRepository
  alias PurseCraft.Core.Schemas.Workspace
  alias PurseCraft.Identity.Schemas.Scope
  alias PurseCraft.PubSub

  @doc """
  Updates a workspace.

  ## Examples

      iex> call(authorized_scope, workspace, %{field: new_value})
      {:ok, %Workspace{}}

      iex> call(authorized_scope, workspace, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

      iex> call(unauthorized_scope, workspace, %{field: new_value})
      {:error, :unauthorized}

  """
  @spec call(Scope.t(), Workspace.t(), WorkspaceRepository.update_attrs()) ::
          {:ok, Workspace.t()} | {:error, Ecto.Changeset.t()} | {:error, :unauthorized}
  def call(%Scope{} = scope, %Workspace{} = workspace, attrs) do
    with :ok <- Policy.authorize(:workspace_update, scope, %{workspace: workspace}),
         {:ok, %Workspace{} = updated_workspace} <- WorkspaceRepository.update(workspace, attrs) do
      message = {:updated, updated_workspace}

      PubSub.broadcast_user_workspace(scope, message)
      PubSub.broadcast_workspace(updated_workspace, message)

      {:ok, updated_workspace}
    end
  end
end

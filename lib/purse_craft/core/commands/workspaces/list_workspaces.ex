defmodule PurseCraft.Core.Commands.Workspaces.ListWorkspaces do
  @moduledoc """
  Lists workspaces associated with the scope's user.
  """

  alias PurseCraft.Core.Policy
  alias PurseCraft.Core.Repositories.WorkspaceRepository
  alias PurseCraft.Core.Schemas.Workspace
  alias PurseCraft.Identity.Schemas.Scope

  @doc """
  Lists workspaces associated with the scope's user.

  ## Examples

      iex> call(authorized_scope)
      [%Workspace{}, ...]

      iex> call(unauthorized_scope)
      {:error, :unauthorized}

  """
  @spec call(Scope.t()) :: list(Workspace.t()) | {:error, :unauthorized}
  def call(%Scope{} = scope) do
    with :ok <- Policy.authorize(:workspace_list, scope) do
      WorkspaceRepository.list_by_user(scope.user.id)
    end
  end
end

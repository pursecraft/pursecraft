defmodule PurseCraft.Core.Commands.Workspaces.GetWorkspaceByExternalId do
  @moduledoc """
  Gets a workspace by its external ID.
  """

  alias PurseCraft.Core.Policy
  alias PurseCraft.Core.Repositories.WorkspaceRepository
  alias PurseCraft.Core.Schemas.Workspace
  alias PurseCraft.Identity.Schemas.Scope

  @doc """
  Gets a workspace by its external ID.

  Raises `LetMe.UnauthorizedError` if the given scope is not authorized to
  view the workspace.

  Raises `Ecto.NoResultsError` if the Workspace does not exist.

  ## Examples

      iex> call!(authorized_scope, "abcd-1234")
      %Workspace{}

      iex> call!(unauthorized_scope, "abcd-1234")
      ** (LetMe.UnauthorizedError)

      iex> call!(authorized_scope, "non-existent-id")
      ** (Ecto.NoResultsError)

  """
  @spec call!(Scope.t(), Ecto.UUID.t()) :: Workspace.t()
  def call!(%Scope{} = scope, external_id) do
    :ok = Policy.authorize!(:workspace_read, scope, %{workspace: %Workspace{external_id: external_id}})

    WorkspaceRepository.get_by_external_id!(external_id)
  end
end

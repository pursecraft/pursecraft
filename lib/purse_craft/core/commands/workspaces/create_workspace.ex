defmodule PurseCraft.Core.Commands.Workspaces.CreateWorkspace do
  @moduledoc """
  Creates a workspace.
  """

  alias PurseCraft.Core.Policy
  alias PurseCraft.Core.Repositories.WorkspaceRepository
  alias PurseCraft.Core.Schemas.Workspace
  alias PurseCraft.Identity.Schemas.Scope
  alias PurseCraft.PubSub

  @doc """
  Creates a workspace.

  ## Examples

      iex> call(authorized_scope, %{field: value})
      {:ok, %Workspace{}}

      iex> call(authorized_scope, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

      iex> call(unauthorized_scope, %{field: value})
      {:error, :unauthorized}

  """
  @spec call(Scope.t(), WorkspaceRepository.create_attrs()) ::
          {:ok, Workspace.t()} | {:error, Ecto.Changeset.t()} | {:error, :unauthorized}
  def call(%Scope{} = scope, attrs \\ %{}) do
    with :ok <- Policy.authorize(:workspace_create, scope),
         {:ok, workspace} <- WorkspaceRepository.create(attrs, scope.user.id) do
      PubSub.broadcast_user_workspace(scope, {:created, workspace})
      {:ok, workspace}
    end
  end
end

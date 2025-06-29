defmodule PurseCraft.Core do
  @moduledoc """
  The Core context contains fundamental business entities that are shared
  across multiple contexts within PurseCraft.

  ## Core Entities

  - `Workspace` - Primary tenant boundary and aggregate root
  - `WorkspaceUser` - Authorization and role-based access control
  """

  import Ecto.Query, warn: false

  alias PurseCraft.Core.Commands.Workspaces.ChangeWorkspace
  alias PurseCraft.Core.Commands.Workspaces.CreateWorkspace
  alias PurseCraft.Core.Commands.Workspaces.DeleteWorkspace
  alias PurseCraft.Core.Commands.Workspaces.FetchWorkspaceByExternalId
  alias PurseCraft.Core.Commands.Workspaces.GetWorkspaceByExternalId
  alias PurseCraft.Core.Commands.Workspaces.ListWorkspaces
  alias PurseCraft.Core.Commands.Workspaces.UpdateWorkspace
  alias PurseCraft.Core.Repositories.WorkspaceRepository
  alias PurseCraft.Core.Schemas.Workspace
  alias PurseCraft.Identity.Schemas.Scope

  @doc """
  Returns the list of workspaces.

  ## Examples

      iex> list_workspaces(authorized_scope)
      [%Workspace{}, ...]

      iex> list_workspaces(unauthorized_scope)
      {:error, :unauthorized}

  """
  @spec list_workspaces(Scope.t()) :: list(Workspace.t()) | {:error, :unauthorized}
  defdelegate list_workspaces(scope), to: ListWorkspaces, as: :call

  @doc """
  Gets a single `Workspace` by its `external_id`.

  Raises `LetMe.UnauthorizedError` if the given scope is not authorized to
  view the workspace.

  Raises `Ecto.NoResultsError` if the Workspace does not exist.

  ## Examples

      iex> get_workspace_by_external_id!(authorized_scope, abcd-1234)
      %Workspace{}

      iex> get_workspace_by_external_id!(unauthorized_scope, abcd-1234)
      ** (LetMe.UnauthorizedError)

  """
  @spec get_workspace_by_external_id!(Scope.t(), Ecto.UUID.t()) :: Workspace.t()
  defdelegate get_workspace_by_external_id!(scope, external_id), to: GetWorkspaceByExternalId, as: :call!

  @doc """
  Fetches a single `Workspace` by its `external_id` with optional preloading of associations.

  Returns a tuple of `{:ok, workspace}` if the workspace exists, or `{:error, :not_found}` if not found.
  Returns `{:error, :unauthorized}` if the given scope is not authorized to view the workspace.

  ## Preloading options

  The `:preload` option accepts a list of associations to preload. For example:

  - `[:categories]` - preloads only categories
  - `[categories: :envelopes]` - preloads categories and their envelopes

  ## Examples

      iex> fetch_workspace_by_external_id(authorized_scope, "abcd-1234", preload: [categories: :envelopes])
      {:ok, %Workspace{categories: [%Category{envelopes: [%Envelope{}, ...]}]}}

      iex> fetch_workspace_by_external_id(authorized_scope, "invalid-id")
      {:error, :not_found}

      iex> fetch_workspace_by_external_id(unauthorized_scope, "abcd-1234")
      {:error, :unauthorized}

  """
  @spec fetch_workspace_by_external_id(Scope.t(), Ecto.UUID.t(), WorkspaceRepository.get_workspace_options()) ::
          {:ok, Workspace.t()} | {:error, :not_found | :unauthorized}
  defdelegate fetch_workspace_by_external_id(scope, external_id, opts \\ []), to: FetchWorkspaceByExternalId, as: :call

  @doc """
  Creates a workspace.

  ## Examples

      iex> create_workspace(authorized_scope, %{field: value})
      {:ok, %Workspace{}}

      iex> create_workspace(authorized_scope, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

      iex> create_workspace(unauthorized_scope, %{field: value})
      {:error, :unauthorized}

  """
  @spec create_workspace(Scope.t(), map()) :: {:ok, Workspace.t()} | {:error, Ecto.Changeset.t() | :unauthorized}
  defdelegate create_workspace(scope, attrs \\ %{}), to: CreateWorkspace, as: :call

  @doc """
  Updates a workspace.

  ## Examples

      iex> update_workspace(authorized_scope, workspace, %{field: new_value})
      {:ok, %Workspace{}}

      iex> update_workspace(authorized_scope, workspace, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

      iex> update_workspace(unauthorized_scope, workspace, %{field: new_value})
      {:error, :unauthorized}

  """
  @spec update_workspace(Scope.t(), Workspace.t(), map()) ::
          {:ok, Workspace.t()} | {:error, Ecto.Changeset.t() | :unauthorized}
  defdelegate update_workspace(scope, workspace, attrs), to: UpdateWorkspace, as: :call

  @doc """
  Deletes a workspace.

  ## Examples

      iex> delete_workspace(authorized_scope, workspace)
      {:ok, %Workspace{}}

      iex> delete_workspace(unauthorized_scope, workspace)
      {:error, :unauthorized}

  """
  @spec delete_workspace(Scope.t(), Workspace.t()) :: {:ok, Workspace.t()} | {:error, :unauthorized}
  defdelegate delete_workspace(scope, workspace), to: DeleteWorkspace, as: :call

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking workspace changes.

  ## Examples

      iex> change_workspace(workspace)
      %Ecto.Changeset{data: %Workspace{}}

  """
  @spec change_workspace(Workspace.t(), map()) :: Ecto.Changeset.t()
  defdelegate change_workspace(workspace, attrs \\ %{}), to: ChangeWorkspace, as: :call

end

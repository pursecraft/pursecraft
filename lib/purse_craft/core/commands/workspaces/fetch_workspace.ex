defmodule PurseCraft.Core.Commands.Workspaces.FetchWorkspace do
  @moduledoc """
  Fetches a workspace by its ID with optional preloading of associations.
  """

  alias PurseCraft.Core.Policy
  alias PurseCraft.Core.Repositories.WorkspaceRepository
  alias PurseCraft.Core.Schemas.Workspace
  alias PurseCraft.Identity.Schemas.Scope
  alias PurseCraft.Utilities

  @doc """
  Fetches a workspace by its ID without authorization (for internal use).

  Returns a tuple of `{:ok, workspace}` if the workspace exists, or `{:error, :not_found}` if not found.

  ## Preloading options

  The `:preload` option accepts a list of associations to preload. For example:

  - `[:categories]` - preloads only categories
  - `[categories: :envelopes]` - preloads categories and their envelopes

  ## Examples

      iex> FetchWorkspace.call(123, preload: [categories: :envelopes])
      {:ok, %Workspace{categories: [%Category{envelopes: [%Envelope{}, ...]}]}}

      iex> FetchWorkspace.call(999)
      {:error, :not_found}

  """
  @spec call(integer(), WorkspaceRepository.get_workspace_options()) ::
          {:ok, Workspace.t()} | {:error, :not_found}
  def call(id, opts \\ []) do
    id
    |> WorkspaceRepository.get_by_id(opts)
    |> Utilities.to_result()
  end

  @doc """
  Fetches a workspace by its ID with optional preloading of associations.

  Returns a tuple of `{:ok, workspace}` if the workspace exists, or `{:error, :not_found}` if not found.
  Returns `{:error, :unauthorized}` if the given scope is not authorized to view the workspace.

  ## Preloading options

  The `:preload` option accepts a list of associations to preload. For example:

  - `[:categories]` - preloads only categories
  - `[categories: :envelopes]` - preloads categories and their envelopes

  ## Examples

      iex> FetchWorkspace.call(123, preload: [categories: :envelopes], scope)
      {:ok, %Workspace{categories: [%Category{envelopes: [%Envelope{}, ...]}]}}

      iex> FetchWorkspace.call(999, [], scope)
      {:error, :not_found}

      iex> FetchWorkspace.call(123, [], unauthorized_scope)
      {:error, :unauthorized}

  """
  @spec call(integer(), WorkspaceRepository.get_workspace_options(), Scope.t()) ::
          {:ok, Workspace.t()} | {:error, :not_found | :unauthorized}
  def call(id, opts, %Scope{} = scope) do
    with :ok <- Policy.authorize(:workspace_read, scope, %{workspace: %Workspace{id: id}}) do
      call(id, opts)
    end
  end
end

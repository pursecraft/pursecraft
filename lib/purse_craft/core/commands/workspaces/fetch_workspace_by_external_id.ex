defmodule PurseCraft.Core.Commands.Workspaces.FetchWorkspaceByExternalId do
  @moduledoc """
  Fetches a workspace by its external ID with optional preloading of associations.
  """

  alias PurseCraft.Core.Policy
  alias PurseCraft.Core.Repositories.WorkspaceRepository
  alias PurseCraft.Core.Schemas.Workspace
  alias PurseCraft.Identity.Schemas.Scope
  alias PurseCraft.Utilities

  @doc """
  Fetches a workspace by its external ID with optional preloading of associations.

  Returns a tuple of `{:ok, workspace}` if the workspace exists, or `{:error, :not_found}` if not found.
  Returns `{:error, :unauthorized}` if the given scope is not authorized to view the workspace.

  ## Preloading options

  The `:preload` option accepts a list of associations to preload. For example:

  - `[:categories]` - preloads only categories
  - `[categories: :envelopes]` - preloads categories and their envelopes

  ## Examples

      iex> call(authorized_scope, "abcd-1234", preload: [categories: :envelopes])
      {:ok, %Workspace{categories: [%Category{envelopes: [%Envelope{}, ...]}]}}

      iex> call(authorized_scope, "invalid-id")
      {:error, :not_found}

      iex> call(unauthorized_scope, "abcd-1234")
      {:error, :unauthorized}

  """
  @spec call(Scope.t(), Ecto.UUID.t(), WorkspaceRepository.get_workspace_options()) ::
          {:ok, Workspace.t()} | {:error, :not_found | :unauthorized}
  def call(%Scope{} = scope, external_id, opts \\ []) do
    with :ok <- Policy.authorize(:workspace_read, scope, %{workspace: %Workspace{external_id: external_id}}) do
      external_id
      |> WorkspaceRepository.get_by_external_id(opts)
      |> Utilities.to_result()
    end
  end
end

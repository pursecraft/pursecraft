defmodule PurseCraft.Budgeting.Commands.Categories.ListCategories do
  @moduledoc """
  Returns a list of categories for a given workspace.
  """

  alias PurseCraft.Budgeting.Policy
  alias PurseCraft.Budgeting.Repositories.CategoryRepository
  alias PurseCraft.Budgeting.Schemas.Category
  alias PurseCraft.Core.Schemas.Workspace
  alias PurseCraft.Identity.Schemas.Scope
  alias PurseCraft.Types

  @type option :: {:preload, Types.preload()}
  @type options :: [option()]

  @doc """
  Returns a list of categories for a given workspace.

  ## Preloading options

  The `:preload` option accepts a list of associations to preload. For example:

  - `[:envelopes]` - preloads the envelopes associated with categories

  ## Examples

      iex> call(authorized_scope, workspace)
      [%Category{}, ...]

      iex> call(authorized_scope, workspace, preload: [:envelopes])
      [%Category{envelopes: [%Envelope{}, ...]}, ...]

      iex> call(unauthorized_scope, workspace)
      {:error, :unauthorized}

  """
  @spec call(Scope.t(), Workspace.t(), options()) :: list(Category.t()) | {:error, :unauthorized}
  def call(%Scope{} = scope, %Workspace{} = workspace, opts \\ []) do
    with :ok <- Policy.authorize(:category_read, scope, %{workspace: workspace}) do
      CategoryRepository.list_by_workspace_id(workspace.id, opts)
    end
  end
end

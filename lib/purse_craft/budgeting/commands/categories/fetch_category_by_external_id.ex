defmodule PurseCraft.Budgeting.Commands.Categories.FetchCategoryByExternalId do
  @moduledoc """
  Fetches a category by external ID for a given workspace.
  """

  alias PurseCraft.Budgeting.Policy
  alias PurseCraft.Budgeting.Repositories.CategoryRepository
  alias PurseCraft.Budgeting.Schemas.Category
  alias PurseCraft.Core.Schemas.Workspace
  alias PurseCraft.Identity.Schemas.Scope
  alias PurseCraft.Types
  alias PurseCraft.Utilities

  @type option :: {:preload, Types.preload()}
  @type options :: [option()]

  @doc """
  Fetches a category by external ID for a given workspace.

  ## Examples

      iex> call(authorized_scope, workspace, "abcd-1234", preload: [:envelopes])
      {:ok, %Category{envelopes: [%Envelope{}, ...]}}

      iex> call(authorized_scope, workspace, "invalid-id")
      {:error, :not_found}

      iex> call(unauthorized_scope, workspace, "abcd-1234")
      {:error, :unauthorized}

  """
  @spec call(Scope.t(), Workspace.t(), Ecto.UUID.t(), options()) ::
          {:ok, Category.t()} | {:error, :not_found | :unauthorized}
  def call(%Scope{} = scope, %Workspace{} = workspace, external_id, opts \\ []) do
    with :ok <- Policy.authorize(:category_read, scope, %{workspace: workspace}) do
      external_id
      |> CategoryRepository.get_by_external_id_and_workspace_id(workspace.id, opts)
      |> Utilities.to_result()
    end
  end
end

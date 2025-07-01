defmodule PurseCraft.Budgeting.Commands.Categories.DeleteCategory do
  @moduledoc """
  Deletes a category.
  """

  alias PurseCraft.Budgeting.Policy
  alias PurseCraft.Budgeting.Repositories.CategoryRepository
  alias PurseCraft.Budgeting.Schemas.Category
  alias PurseCraft.Core.Schemas.Workspace
  alias PurseCraft.Identity.Schemas.Scope
  alias PurseCraft.PubSub

  @doc """
  Deletes a category.

  ## Examples

      iex> call(authorized_scope, workspace, category)
      {:ok, %Category{}}

      iex> call(unauthorized_scope, workspace, category)
      {:error, :unauthorized}

  """
  @spec call(Scope.t(), Workspace.t(), Category.t()) ::
          {:ok, Category.t()} | {:error, Ecto.Changeset.t()} | {:error, :unauthorized}
  def call(%Scope{} = scope, %Workspace{} = workspace, %Category{} = category) do
    with :ok <- Policy.authorize(:category_delete, scope, %{workspace: workspace}),
         {:ok, %Category{} = category} <- CategoryRepository.delete(category) do
      PubSub.broadcast_workspace(workspace, {:category_deleted, category})
      {:ok, category}
    end
  end
end

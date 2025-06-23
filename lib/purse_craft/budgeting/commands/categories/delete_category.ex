defmodule PurseCraft.Budgeting.Commands.Categories.DeleteCategory do
  @moduledoc """
  Deletes a category.
  """

  alias PurseCraft.Budgeting.Policy
  alias PurseCraft.Budgeting.Repositories.CategoryRepository
  alias PurseCraft.Budgeting.Schemas.Book
  alias PurseCraft.Budgeting.Schemas.Category
  alias PurseCraft.Identity.Schemas.Scope
  alias PurseCraft.PubSub

  @doc """
  Deletes a category.

  ## Examples

      iex> call(authorized_scope, book, category)
      {:ok, %Category{}}

      iex> call(unauthorized_scope, book, category)
      {:error, :unauthorized}

  """
  @spec call(Scope.t(), Book.t(), Category.t()) ::
          {:ok, Category.t()} | {:error, Ecto.Changeset.t()} | {:error, :unauthorized}
  def call(%Scope{} = scope, %Book{} = book, %Category{} = category) do
    with :ok <- Policy.authorize(:category_delete, scope, %{book: book}),
         {:ok, %Category{} = category} <- CategoryRepository.delete(category) do
      PubSub.broadcast_book(book, {:category_deleted, category})
      {:ok, category}
    end
  end
end

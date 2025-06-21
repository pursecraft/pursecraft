defmodule PurseCraft.Budgeting.Commands.Categories.ListCategories do
  @moduledoc """
  Returns a list of categories for a given book.
  """

  alias PurseCraft.Budgeting.Policy
  alias PurseCraft.Budgeting.Repositories.CategoryRepository
  alias PurseCraft.Budgeting.Schemas.Category
  alias PurseCraft.Identity.Schemas.Book
  alias PurseCraft.Identity.Schemas.Scope
  alias PurseCraft.Types

  @type option :: {:preload, Types.preload()}
  @type options :: [option()]

  @doc """
  Returns a list of categories for a given book.

  ## Preloading options

  The `:preload` option accepts a list of associations to preload. For example:

  - `[:envelopes]` - preloads the envelopes associated with categories

  ## Examples

      iex> call(authorized_scope, book)
      [%Category{}, ...]

      iex> call(authorized_scope, book, preload: [:envelopes])
      [%Category{envelopes: [%Envelope{}, ...]}, ...]

      iex> call(unauthorized_scope, book)
      {:error, :unauthorized}

  """
  @spec call(Scope.t(), Book.t(), options()) :: list(Category.t()) | {:error, :unauthorized}
  def call(%Scope{} = scope, %Book{} = book, opts \\ []) do
    with :ok <- Policy.authorize(:category_read, scope, %{book: book}) do
      CategoryRepository.list_by_book_id(book.id, opts)
    end
  end
end

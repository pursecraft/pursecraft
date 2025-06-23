defmodule PurseCraft.Budgeting.Commands.Books.FetchBookByExternalId do
  @moduledoc """
  Fetches a book by its external ID with optional preloading of associations.
  """

  alias PurseCraft.Budgeting.Policy
  alias PurseCraft.Budgeting.Repositories.BookRepository
  alias PurseCraft.Budgeting.Schemas.Book
  alias PurseCraft.Identity.Schemas.Scope
  alias PurseCraft.Utilities

  @doc """
  Fetches a book by its external ID with optional preloading of associations.

  Returns a tuple of `{:ok, book}` if the book exists, or `{:error, :not_found}` if not found.
  Returns `{:error, :unauthorized}` if the given scope is not authorized to view the book.

  ## Preloading options

  The `:preload` option accepts a list of associations to preload. For example:

  - `[:categories]` - preloads only categories
  - `[categories: :envelopes]` - preloads categories and their envelopes

  ## Examples

      iex> call(authorized_scope, "abcd-1234", preload: [categories: :envelopes])
      {:ok, %Book{categories: [%Category{envelopes: [%Envelope{}, ...]}]}}

      iex> call(authorized_scope, "invalid-id")
      {:error, :not_found}

      iex> call(unauthorized_scope, "abcd-1234")
      {:error, :unauthorized}

  """
  @spec call(Scope.t(), Ecto.UUID.t(), BookRepository.get_book_options()) ::
          {:ok, Book.t()} | {:error, :not_found | :unauthorized}
  def call(%Scope{} = scope, external_id, opts \\ []) do
    with :ok <- Policy.authorize(:book_read, scope, %{book: %Book{external_id: external_id}}) do
      external_id
      |> BookRepository.get_by_external_id_with_options(opts)
      |> Utilities.to_result()
    end
  end
end

defmodule PurseCraft.Budgeting.Commands.Books.GetBookByExternalId do
  @moduledoc """
  Gets a book by its external ID.
  """

  alias PurseCraft.Budgeting.Policy
  alias PurseCraft.Budgeting.Repositories.BookRepository
  alias PurseCraft.Identity.Schemas.Book
  alias PurseCraft.Identity.Schemas.Scope

  @doc """
  Gets a book by its external ID.

  Raises `LetMe.UnauthorizedError` if the given scope is not authorized to
  view the book.

  Raises `Ecto.NoResultsError` if the Book does not exist.

  ## Examples

      iex> call!(authorized_scope, "abcd-1234")
      %Book{}

      iex> call!(unauthorized_scope, "abcd-1234")
      ** (LetMe.UnauthorizedError)

      iex> call!(authorized_scope, "non-existent-id")
      ** (Ecto.NoResultsError)

  """
  @spec call!(Scope.t(), Ecto.UUID.t()) :: Book.t()
  def call!(%Scope{} = scope, external_id) do
    :ok = Policy.authorize!(:book_read, scope, %{book: %Book{external_id: external_id}})

    BookRepository.get_by_external_id!(external_id)
  end
end

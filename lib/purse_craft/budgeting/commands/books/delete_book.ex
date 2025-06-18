defmodule PurseCraft.Budgeting.Commands.Books.DeleteBook do
  @moduledoc """
  Deletes a book.
  """

  alias PurseCraft.Budgeting.Commands.PubSub.BroadcastUserBook
  alias PurseCraft.Budgeting.Policy
  alias PurseCraft.Budgeting.Repositories.BookRepository
  alias PurseCraft.Budgeting.Schemas.Book
  alias PurseCraft.Identity.Schemas.Scope
  alias PurseCraft.PubSub.BroadcastBook

  @doc """
  Deletes a book.

  ## Examples

      iex> call(authorized_scope, book)
      {:ok, %Book{}}

      iex> call(unauthorized_scope, book)
      {:error, :unauthorized}

  """
  @spec call(Scope.t(), Book.t()) :: {:ok, Book.t()} | {:error, :unauthorized}
  def call(%Scope{} = scope, %Book{} = book) do
    with :ok <- Policy.authorize(:book_delete, scope, %{book: book}),
         {:ok, %Book{} = book} <- BookRepository.delete(book) do
      message = {:deleted, book}

      BroadcastUserBook.call(scope, message)
      BroadcastBook.call(book, message)

      {:ok, book}
    end
  end
end

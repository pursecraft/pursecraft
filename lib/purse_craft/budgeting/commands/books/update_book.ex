defmodule PurseCraft.Budgeting.Commands.Books.UpdateBook do
  @moduledoc """
  Updates a book.
  """

  alias PurseCraft.Budgeting.Policy
  alias PurseCraft.Core.Repositories.BookRepository
  alias PurseCraft.Core.Schemas.Book
  alias PurseCraft.Identity.Schemas.Scope
  alias PurseCraft.PubSub

  @doc """
  Updates a book.

  ## Examples

      iex> call(authorized_scope, book, %{field: new_value})
      {:ok, %Book{}}

      iex> call(authorized_scope, book, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

      iex> call(unauthorized_scope, book, %{field: new_value})
      {:error, :unauthorized}

  """
  @spec call(Scope.t(), Book.t(), BookRepository.update_attrs()) ::
          {:ok, Book.t()} | {:error, Ecto.Changeset.t()} | {:error, :unauthorized}
  def call(%Scope{} = scope, %Book{} = book, attrs) do
    with :ok <- Policy.authorize(:book_update, scope, %{book: book}),
         {:ok, %Book{} = updated_book} <- BookRepository.update(book, attrs) do
      message = {:updated, updated_book}

      PubSub.broadcast_user_book(scope, message)
      PubSub.broadcast_book(updated_book, message)

      {:ok, updated_book}
    end
  end
end

defmodule PurseCraft.Budgeting.Commands.Books.CreateBook do
  @moduledoc """
  Command for creating a new book.
  """

  alias PurseCraft.Budgeting.Commands.PubSub.BroadcastUserBook
  alias PurseCraft.Budgeting.Policy
  alias PurseCraft.Budgeting.Repositories.BookRepository
  alias PurseCraft.Budgeting.Schemas.Book
  alias PurseCraft.Identity.Schemas.Scope

  @doc """
  Creates a book.

  ## Examples

      iex> call(authorized_scope, %{field: value})
      {:ok, %Book{}}

      iex> call(authorized_scope, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

      iex> call(unauthorized_scope, %{field: value})
      {:error, :unauthorized}

  """
  @spec call(Scope.t(), BookRepository.create_attrs()) ::
          {:ok, Book.t()} | {:error, Ecto.Changeset.t()} | {:error, :unauthorized}
  def call(%Scope{} = scope, attrs \\ %{}) do
    with :ok <- Policy.authorize(:book_create, scope),
         {:ok, book} <- BookRepository.create_with_owner(attrs, scope.user.id) do
      BroadcastUserBook.call(scope, {:created, book})
      {:ok, book}
    end
  end
end

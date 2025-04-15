defmodule PurseCraft.Budgeting do
  @moduledoc """
  The Budgeting context.
  """

  import Ecto.Query, warn: false

  alias Ecto.Multi
  alias PurseCraft.Budgeting.Schemas.Book
  alias PurseCraft.Budgeting.Schemas.BookUser
  alias PurseCraft.Identity.Schemas.Scope
  alias PurseCraft.Policy
  alias PurseCraft.Repo

  @doc """
  Subscribes to scoped notifications about any book changes.

  The broadcasted messages match the pattern:

    * {:created, %Book{}}
    * {:updated, %Book{}}
    * {:deleted, %Book{}}

  """
  def subscribe_books(%Scope{} = scope) do
    key = scope.user.id

    Phoenix.PubSub.subscribe(PurseCraft.PubSub, "user:#{key}:books")
  end

  defp broadcast(%Scope{} = scope, message) do
    key = scope.user.id

    Phoenix.PubSub.broadcast(PurseCraft.PubSub, "user:#{key}:books", message)
  end

  @doc """
  Returns the list of books.

  ## Examples

      iex> list_books(scope)
      [%Book{}, ...]

  """
  def list_books(%Scope{} = scope) do
    Repo.all(from book in Book, where: book.user_id == ^scope.user.id)
  end

  @doc """
  Gets a single book.

  Raises `Ecto.NoResultsError` if the Book does not exist.

  ## Examples

      iex> get_book!(123)
      %Book{}

      iex> get_book!(456)
      ** (Ecto.NoResultsError)

  """
  def get_book!(%Scope{} = scope, id) do
    Repo.get_by!(Book, id: id, user_id: scope.user.id)
  end

  @doc """
  Gets a single `Book` by its `external_id`.

  Raises `LetMe.UnauthorizedError` if the given scope is not authorized to
  view the book.

  Raises `Ecto.NoResultsError` if the Book does not exist.

  ## Examples

      iex> get_book_by_external_id!(authorized_scope, abcd-1234)
      %Book{}

      iex> get_book_by_external_id!(authorized_scope, efgh-4321)
      ** (Ecto.NoResultsError)

      iex> get_book_by_external_id!(unauthorized_scope, abcd-1234)
      ** (LetMe.UnauthorizedError)

  """
  def get_book_by_external_id!(%Scope{} = scope, external_id) do
    :ok = Policy.authorize!(:book_read, scope)

    Repo.get_by!(Book, external_id: external_id)
  end

  @doc """
  Creates a book.

  ## Examples

      iex> create_book(%{field: value})
      {:ok, %Book{}}

      iex> create_book(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_book(%Scope{} = scope, attrs \\ %{}) do
    with {:ok, book = %Book{}} <-
           %Book{}
           |> Book.changeset(attrs, scope)
           |> Repo.insert() do
      broadcast(scope, {:created, book})
      {:ok, book}
    end
  end

  @doc """
  Updates a book.

  ## Examples

      iex> update_book(book, %{field: new_value})
      {:ok, %Book{}}

      iex> update_book(book, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_book(%Scope{} = scope, %Book{} = book, attrs) do
    true = book.user_id == scope.user.id

    with {:ok, book = %Book{}} <-
           book
           |> Book.changeset(attrs, scope)
           |> Repo.update() do
      broadcast(scope, {:updated, book})
      {:ok, book}
    end
  end

  @doc """
  Deletes a book.

  ## Examples

      iex> delete_book(book)
      {:ok, %Book{}}

      iex> delete_book(book)
      {:error, %Ecto.Changeset{}}

  """
  def delete_book(%Scope{} = scope, %Book{} = book) do
    true = book.user_id == scope.user.id

    with {:ok, book = %Book{}} <-
           Repo.delete(book) do
      broadcast(scope, {:deleted, book})
      {:ok, book}
    end
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking book changes.

  ## Examples

      iex> change_book(book)
      %Ecto.Changeset{data: %Book{}}

  """
  def change_book(%Scope{} = scope, %Book{} = book, attrs \\ %{}) do
    true = book.user_id == scope.user.id

    Book.changeset(book, attrs, scope)
  end
end

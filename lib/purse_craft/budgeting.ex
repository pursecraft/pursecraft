defmodule PurseCraft.Budgeting do
  @moduledoc """
  The Budgeting context.
  """

  import Ecto.Query, warn: false

  alias Ecto.Multi
  alias PurseCraft.Budgeting.Policy
  alias PurseCraft.Budgeting.Schemas.Book
  alias PurseCraft.Budgeting.Schemas.BookUser
  alias PurseCraft.Identity.Schemas.Scope
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

      iex> list_books(authorized_scope)
      [%Book{}, ...]

      iex> list_books(unauthorized_scope)
      {:error, :unauthorized}

  """
  def list_books(%Scope{} = scope) do
    with :ok <- Policy.authorize(:book_list, scope) do
      Book
      |> join(:inner, [b], bu in BookUser, on: bu.book_id == b.id)
      |> where([_b, bu], bu.user_id == ^scope.user.id)
      |> Repo.all()
    end
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

      iex> get_book_by_external_id!(unauthorized_scope, abcd-1234)
      ** (LetMe.UnauthorizedError)

  """
  def get_book_by_external_id!(%Scope{} = scope, external_id) do
    :ok = Policy.authorize!(:book_read, scope, %{book: %Book{external_id: external_id}})

    Repo.get_by!(Book, external_id: external_id)
  end

  @doc """
  Creates a book.

  ## Examples

      iex> create_book(authorized_scope, %{field: value})
      {:ok, %Book{}}

      iex> create_book(authorized_scope, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

      iex> create_book(unauthorized_scope, %{field: value})
      {:error, :unauthorized}

  """
  def create_book(%Scope{} = scope, attrs \\ %{}) do
    with :ok <- Policy.authorize(:book_create, scope) do
      Multi.new()
      |> Multi.insert(:book, Book.changeset(%Book{}, attrs))
      |> Multi.insert(:book_user, fn %{book: book} ->
        BookUser.changeset(%BookUser{}, %{
          book_id: book.id,
          user_id: scope.user.id,
          role: :owner
        })
      end)
      |> Repo.transaction()
      |> case do
        {:ok, %{book: book}} ->
          broadcast(scope, {:created, book})
          {:ok, book}

        {:error, _operations, changeset, _changes} ->
          {:error, changeset}
      end
    end
  end

  @doc """
  Updates a book.

  ## Examples

      iex> update_book(authorized_scope, book, %{field: new_value})
      {:ok, %Book{}}

      iex> update_book(authorized_scope, book, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

      iex> update_book(unauthorized_scope, book, %{field: new_value})
      {:error, :unauthorized}

  """
  def update_book(%Scope{} = scope, %Book{} = book, attrs) do
    with :ok <- Policy.authorize(:book_update, scope, %{book: book}),
         {:ok, %Book{} = book} <-
           book
           |> Book.changeset(attrs)
           |> Repo.update() do
      broadcast(scope, {:updated, book})
      {:ok, book}
    end
  end

  @doc """
  Deletes a book.

  ## Examples

      iex> delete_book(authorized_scope, book)
      {:ok, %Book{}}

      iex> delete_book(authorized_scope, book)
      {:error, %Ecto.Changeset{}}

      iex> delete_book(authorized_scope, book)
      {:error, :unauthorized}

  """
  def delete_book(%Scope{} = scope, %Book{} = book) do
    with :ok <- Policy.authorize(:book_delete, scope, %{book: book}),
         {:ok, %Book{} = book} <-
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
  def change_book(%Book{} = book, attrs \\ %{}) do
    Book.changeset(book, attrs)
  end
end

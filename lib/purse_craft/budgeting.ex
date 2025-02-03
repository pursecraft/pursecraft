defmodule PurseCraft.Budgeting do
  @moduledoc """
  The Budgeting context.
  """

  import Ecto.Query, warn: false
  alias PurseCraft.Repo

  alias PurseCraft.Budgeting.Schemas.Book

  @type create_book_attrs :: %{name: String.t() | nil} | %{}
  @type update_book_attrs :: %{name: String.t() | nil} | %{}
  @type change_book_attrs :: %{name: String.t() | nil} | %{}

  @doc """
  Returns the list of books.

  ## Examples

      iex> list_books()
      [%Book{}, ...]

  """
  @spec list_books() :: list(Book.t())
  def list_books do
    Repo.all(Book)
  end

  @doc """
  Gets a single book.

  Returns `nil` if the Book does not exist.

  ## Examples

      iex> get_book(123)
      %Book{}

      iex> get_book(456)
      nil

  """
  @spec get_book(integer()) :: Book.t() | nil
  def get_book(id), do: Repo.get(Book, id)

  @doc """
  Gets a single book.

  Returns `{:error, :not_found}` if the Book does not exist.

  ## Examples

      iex> fetch_book(123)
      {:ok, %Book{}}

      iex> fetch_book(456)
      {:error, :not_found}

  """
  @spec fetch_book(integer()) :: {:ok, Book.t()} | {:error, :not_found}
  def fetch_book(id) do
    case get_book(id) do
      nil ->
        {:error, :not_found}

      book ->
        {:ok, book}
    end
  end

  @doc """
  Creates a book.

  ## Examples

      iex> create_book(%{field: value})
      {:ok, %Book{}}

      iex> create_book(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  @spec create_book(create_book_attrs()) :: {:ok, Book.t()} | {:error, Ecto.Changeset.t()}
  def create_book(attrs \\ %{}) do
    %Book{}
    |> Book.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a book.

  ## Examples

      iex> update_book(book, %{field: new_value})
      {:ok, %Book{}}

      iex> update_book(book, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  @spec update_book(Book.t(), update_book_attrs()) ::
          {:ok, Book.t()} | {:error, Ecto.Changeset.t()}
  def update_book(%Book{} = book, attrs) do
    book
    |> Book.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a book.

  ## Examples

      iex> delete_book(book)
      {:ok, %Book{}}

      iex> delete_book(book)
      {:error, %Ecto.Changeset{}}

  """
  @spec delete_book(Book.t()) :: {:ok, Book.t()} | {:error, Ecto.Changeset.t()}
  def delete_book(%Book{} = book) do
    Repo.delete(book)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking book changes.

  ## Examples

      iex> change_book(book)
      %Ecto.Changeset{data: %Book{}}

  """
  @spec change_book(Book.t(), change_book_attrs()) :: Ecto.Changeset.t()
  def change_book(%Book{} = book, attrs \\ %{}) do
    Book.changeset(book, attrs)
  end
end

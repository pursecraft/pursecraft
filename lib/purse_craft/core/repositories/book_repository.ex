defmodule PurseCraft.Core.Repositories.BookRepository do
  @moduledoc """
  Repository for `Book`.
  """

  alias Ecto.Multi
  alias PurseCraft.Core.Queries.BookQuery
  alias PurseCraft.Core.Queries.BookUserQuery
  alias PurseCraft.Core.Schemas.Book
  alias PurseCraft.Core.Schemas.BookUser
  alias PurseCraft.Repo
  alias PurseCraft.Utilities

  @type preload_item :: atom() | {atom(), preload_item()} | [preload_item()]
  @type preload :: preload_item() | [preload_item()]

  @type get_book_option :: {:preload, preload()}
  @type get_book_options :: [get_book_option()]

  @type create_attrs :: %{
          optional(:name) => String.t()
        }

  @type update_attrs :: %{
          optional(:name) => String.t()
        }

  @doc """
  Lists all books for a specific user.

  ## Examples

      iex> list_by_user(user_id)
      [%Book{}, ...]

  """
  @spec list_by_user(integer()) :: list(Book.t())
  def list_by_user(user_id) do
    user_id
    |> BookQuery.by_user()
    |> Repo.all()
  end

  @doc """
  Gets a book by its external ID.

  Raises `Ecto.NoResultsError` if the Book does not exist.

  ## Examples

      iex> get_by_external_id!("abcd-1234")
      %Book{}

      iex> get_by_external_id!("non-existent-id")
      ** (Ecto.NoResultsError)

  """
  @spec get_by_external_id!(Ecto.UUID.t()) :: Book.t()
  def get_by_external_id!(external_id) do
    external_id
    |> BookQuery.by_external_id()
    |> Repo.one!()
  end

  @doc """
  Gets a book by its external ID with optional preloading.

  Returns the book if it exists, or `nil` if not found.

  ## Options

  The `:preload` option accepts a list of associations to preload. For example:

  - `[preload: [:categories]]` - preloads only categories
  - `[preload: [categories: :envelopes]]` - preloads categories and their envelopes

  ## Examples

      iex> get_by_external_id("abcd-1234")
      %Book{}

      iex> get_by_external_id("abcd-1234", preload: [:categories])
      %Book{categories: [...]}

      iex> get_by_external_id("non-existent-id")
      nil

  """
  @spec get_by_external_id(Ecto.UUID.t(), get_book_options()) :: Book.t() | nil
  def get_by_external_id(external_id, opts \\ []) do
    preloads = Keyword.get(opts, :preload, [])

    external_id
    |> BookQuery.by_external_id()
    |> Repo.one()
    |> Utilities.maybe_preload(preloads)
  end

  @doc """
  Creates a book and associates it with a user as the owner.

  ## Examples

      iex> create(%{name: "Household"}, user_id)
      {:ok, %Book{}}

      iex> create(%{name: ""}, user_id)
      {:error, %Ecto.Changeset{}}

  """

  @spec create(create_attrs(), integer()) :: {:ok, Book.t()} | {:error, Ecto.Changeset.t()}
  def create(attrs, user_id) do
    Multi.new()
    |> Multi.insert(:book, Book.changeset(%Book{}, attrs))
    |> Multi.insert(:book_user, fn %{book: book} ->
      BookUser.changeset(%BookUser{}, %{
        book_id: book.id,
        user_id: user_id,
        role: :owner
      })
    end)
    |> Repo.transaction()
    |> case do
      {:ok, %{book: book}} -> {:ok, book}
      {:error, _operations, changeset, _changes} -> {:error, changeset}
    end
  end

  @doc """
  Updates a book.

  ## Examples

      iex> update(%Book{}, %{name: "Updated Name"})
      {:ok, %Book{}}

      iex> update(%Book{}, %{name: ""})
      {:error, %Ecto.Changeset{}}

  """
  @spec update(Book.t(), update_attrs()) :: {:ok, Book.t()} | {:error, Ecto.Changeset.t()}
  def update(%Book{} = book, attrs) do
    book
    |> Book.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a book and its associated BookUser records.

  ## Examples

      iex> delete(%Book{})
      {:ok, %Book{}}

      iex> delete(%Book{})
      {:error, %Ecto.Changeset{}}

  """
  @spec delete(Book.t()) :: {:ok, Book.t()} | {:error, Ecto.Changeset.t()}
  def delete(%Book{} = book) do
    Multi.new()
    |> Multi.delete_all(:delete_book_users, BookUserQuery.by_book_id(book.id))
    |> Multi.delete(:delete_book, book)
    |> Repo.transaction()
    |> case do
      {:ok, %{delete_book: book}} ->
        {:ok, book}

      # coveralls-ignore-start
      {:error, _operation, error, _changes} ->
        {:error, error}
        # coveralls-ignore-stop
    end
  end
end

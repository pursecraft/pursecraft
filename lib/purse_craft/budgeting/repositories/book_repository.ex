defmodule PurseCraft.Budgeting.Repositories.BookRepository do
  @moduledoc """
  Repository for `Book`.
  """

  alias PurseCraft.Budgeting.Queries.BookQueries
  alias PurseCraft.Budgeting.Schemas.Book
  alias PurseCraft.Repo

  @type preload_item :: atom() | {atom(), preload_item()} | [preload_item()]
  @type preload :: preload_item() | [preload_item()]

  @type get_book_option :: {:preload, preload()}
  @type get_book_options :: [get_book_option()]

  @doc """
  Lists all books for a specific user.

  ## Examples

      iex> list_by_user(user_id)
      [%Book{}, ...]

  """
  @spec list_by_user(integer()) :: list(Book.t())
  def list_by_user(user_id) do
    user_id
    |> BookQueries.by_user()
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
    |> BookQueries.by_external_id()
    |> Repo.one!()
  end

  @doc """
  Gets a book by its external ID.

  Returns `nil` if the Book does not exist.

  ## Examples

      iex> get_by_external_id("abcd-1234")
      %Book{}

      iex> get_by_external_id("non-existent-id")
      nil

  """
  @spec get_by_external_id(Ecto.UUID.t()) :: Book.t() | nil
  def get_by_external_id(external_id) do
    external_id
    |> BookQueries.by_external_id()
    |> Repo.one()
  end

  @doc """
  Gets a book by its external ID with options.

  Returns the book if it exists, or `nil` if not found.

  ## Options

  The `:preload` option accepts a list of associations to preload. For example:

  - `[preload: [:categories]]` - preloads only categories
  - `[preload: [categories: :envelopes]]` - preloads categories and their envelopes

  ## Examples

      iex> get_by_external_id_with_options("abcd-1234", preload: [:categories])
      %Book{categories: [...]}

      iex> get_by_external_id_with_options("non-existent-id", preload: [:categories])
      nil

  """
  @spec get_by_external_id_with_options(Ecto.UUID.t(), get_book_options()) :: Book.t() | nil
  def get_by_external_id_with_options(external_id, opts \\ []) do
    case get_by_external_id(external_id) do
      nil ->
        nil

      book ->
        preloads = Keyword.get(opts, :preload, [])
        if preloads == [], do: book, else: Repo.preload(book, preloads)
    end
  end
end

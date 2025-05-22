defmodule PurseCraft.Budgeting.Repositories.CategoryRepository do
  @moduledoc """
  Repository for `Category`.
  """

  alias PurseCraft.Budgeting.Queries.CategoryQueries
  alias PurseCraft.Budgeting.Schemas.Category
  alias PurseCraft.Repo
  alias PurseCraft.Types

  @type get_option :: {:preload, Types.preload()}
  @type get_options :: [get_option()]

  @type list_option :: {:preload, Types.preload()}
  @type list_options :: [list_option()]

  @type create_attrs :: %{
          optional(:name) => String.t(),
          required(:book_id) => integer()
        }

  @doc """
  Lists all categories for a given book ID.

  ## Options

  The `:preload` option accepts a list of associations to preload. For example:

  - `[preload: [:envelopes]]` - preloads only envelopes

  ## Examples

      iex> list_by_book_id(1)
      [%Category{}, ...]

      iex> list_by_book_id(1, preload: [:envelopes])
      [%Category{envelopes: [%Envelope{}, ...]}, ...]

  """
  @spec list_by_book_id(integer(), list_options()) :: list(Category.t())
  def list_by_book_id(book_id, opts \\ []) do
    categories =
      book_id
      |> CategoryQueries.by_book_id()
      |> Repo.all()

    preloads = Keyword.get(opts, :preload, [])
    if preloads == [], do: categories, else: Repo.preload(categories, preloads)
  end

  @doc """
  Creates a category for a book.

  ## Examples

      iex> create(%{name: "Monthly Bills", book_id: 1})
      {:ok, %Category{}}

      iex> create(%{name: "", book_id: 1})
      {:error, %Ecto.Changeset{}}

  """
  @spec create(create_attrs()) :: {:ok, Category.t()} | {:error, Ecto.Changeset.t()}
  def create(attrs) do
    %Category{}
    |> Category.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Gets a category by its external ID and book ID with options.

  Returns the category if it exists, or `nil` if not found.

  ## Options

  The `:preload` option accepts a list of associations to preload. For example:

  - `[preload: [:envelopes]]` - preloads only envelopes

  ## Examples

      iex> get_by_external_id_and_book_id("abcd-1234", 1, preload: [:envelopes])
      %Category{envelopes: [...]}

      iex> get_by_external_id_and_book_id("non-existent-id", 1, preload: [:envelopes])
      nil

  """
  @spec get_by_external_id_and_book_id(Ecto.UUID.t(), integer(), get_options()) :: Category.t() | nil
  def get_by_external_id_and_book_id(external_id, book_id, opts \\ []) do
    external_id
    |> CategoryQueries.by_external_id()
    |> CategoryQueries.by_book_id(book_id)
    |> Repo.one()
    |> case do
      nil ->
        nil

      category ->
        preloads = Keyword.get(opts, :preload, [])
        if preloads == [], do: category, else: Repo.preload(category, preloads)
    end
  end

  @doc """
  Deletes a category.

  ## Examples

      iex> delete(category)
      {:ok, %Category{}}

      iex> delete(category)
      {:error, %Ecto.Changeset{}}

  """
  @spec delete(Category.t()) :: {:ok, Category.t()} | {:error, Ecto.Changeset.t()}
  def delete(category) do
    Repo.delete(category)
  end
end

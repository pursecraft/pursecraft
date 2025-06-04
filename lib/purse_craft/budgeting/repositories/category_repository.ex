defmodule PurseCraft.Budgeting.Repositories.CategoryRepository do
  @moduledoc """
  Repository for `Category`.
  """

  alias PurseCraft.Budgeting.Queries.CategoryQuery
  alias PurseCraft.Budgeting.Schemas.Category
  alias PurseCraft.Repo
  alias PurseCraft.Types

  @type get_option :: {:preload, Types.preload()}
  @type get_options :: [get_option()]

  @type list_option :: {:preload, Types.preload()}
  @type list_options :: [list_option()]

  @type create_attrs :: %{
          optional(:name) => String.t(),
          required(:book_id) => integer(),
          required(:position) => String.t()
        }

  @type update_attrs :: %{
          optional(:name) => String.t()
        }

  @type update_option :: {:preload, Types.preload()}
  @type update_options :: [update_option()]

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
      |> CategoryQuery.by_book_id()
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
    |> CategoryQuery.by_external_id()
    |> CategoryQuery.by_book_id(book_id)
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
  Updates a category with the given attributes.

  ## Options

  The `:preload` option accepts a list of associations to preload. For example:

  - `[preload: [:envelopes]]` - preloads only envelopes

  ## Examples

      iex> update(category, %{name: "Updated Name"})
      {:ok, %Category{}}

      iex> update(category, %{name: "Updated Name"}, preload: [:envelopes])
      {:ok, %Category{envelopes: [%Envelope{}, ...]}}

      iex> update(category, %{name: ""})
      {:error, %Ecto.Changeset{}}

  """
  @spec update(Category.t(), update_attrs(), update_options()) :: {:ok, Category.t()} | {:error, Ecto.Changeset.t()}
  def update(category, attrs, opts \\ []) do
    with {:ok, %Category{} = updated_category} <-
           category
           |> Category.changeset(attrs)
           |> Repo.update() do
      preloads = Keyword.get(opts, :preload, [])
      updated_category = if preloads == [], do: updated_category, else: Repo.preload(updated_category, preloads)
      {:ok, updated_category}
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

  @doc """
  Updates the position of a category.

  ## Examples

      iex> update_position(category, "m")
      {:ok, %Category{position: "m"}}

      iex> update_position(category, "ABC")
      {:error, %Ecto.Changeset{}}

  """
  @spec update_position(Category.t(), String.t()) :: {:ok, Category.t()} | {:error, Ecto.Changeset.t()}
  def update_position(category, new_position) do
    category
    |> Category.position_changeset(%{position: new_position})
    |> Repo.update()
  end

  @doc """
  Gets the position of the first category in a book (ordered by position).

  Returns the position as a string, or nil if no categories exist.

  ## Examples

      iex> get_first_position(1)
      "g"

      iex> get_first_position(999)
      nil

  """
  @spec get_first_position(integer()) :: String.t() | nil
  def get_first_position(book_id) do
    book_id
    |> CategoryQuery.by_book_id()
    |> CategoryQuery.order_by_position()
    |> CategoryQuery.limit(1)
    |> CategoryQuery.select_position()
    |> Repo.one()
  end

  @doc """
  Gets multiple categories by their external IDs.

  Returns a list of categories that match the given external IDs.

  ## Options

  The `:preload` option accepts a list of associations to preload.

  ## Examples

      iex> list_by_external_ids(["id1", "id2", "id3"])
      [%Category{}, %Category{}]

      iex> list_by_external_ids(["id1", "id2"], preload: [:book])
      [%Category{book: %Book{}}, %Category{book: %Book{}}]

  """
  @spec list_by_external_ids([Ecto.UUID.t()], list_options()) :: [Category.t()]
  def list_by_external_ids(external_ids, opts \\ []) when is_list(external_ids) do
    categories =
      external_ids
      |> CategoryQuery.by_external_ids()
      |> Repo.all()

    preloads = Keyword.get(opts, :preload, [])
    if preloads == [], do: categories, else: Repo.preload(categories, preloads)
  end
end

defmodule PurseCraft.Budgeting.Repositories.CategoryRepository do
  @moduledoc """
  Repository for `Category`.
  """

  alias PurseCraft.Budgeting.Queries.CategoryQuery
  alias PurseCraft.Budgeting.Schemas.Category
  alias PurseCraft.Repo
  alias PurseCraft.Types
  alias PurseCraft.Utilities

  @type get_option :: {:preload, Types.preload()}
  @type get_options :: [get_option()]

  @type list_option :: {:preload, Types.preload()}
  @type list_options :: [list_option()]

  @type create_attrs :: %{
          optional(:name) => String.t(),
          required(:workspace_id) => integer(),
          required(:position) => String.t()
        }

  @type update_attrs :: %{
          optional(:name) => String.t()
        }

  @type update_option :: {:preload, Types.preload()}
  @type update_options :: [update_option()]

  @doc """
  Lists all categories for a given workspace ID.

  ## Options

  The `:preload` option accepts a list of associations to preload. For example:

  - `[preload: [:envelopes]]` - preloads only envelopes

  ## Examples

      iex> list_by_workspace_id(1)
      [%Category{}, ...]

      iex> list_by_workspace_id(1, preload: [:envelopes])
      [%Category{envelopes: [%Envelope{}, ...]}, ...]

  """
  @spec list_by_workspace_id(integer(), list_options()) :: list(Category.t())
  def list_by_workspace_id(workspace_id, opts \\ []) do
    workspace_id
    |> CategoryQuery.by_workspace_id()
    |> Repo.all()
    |> Utilities.maybe_preload(opts)
  end

  @doc """
  Creates a category for a workspace.

  ## Examples

      iex> create(%{name: "Monthly Bills", workspace_id: 1})
      {:ok, %Category{}}

      iex> create(%{name: "", workspace_id: 1})
      {:error, %Ecto.Changeset{}}

  """
  @spec create(create_attrs()) :: {:ok, Category.t()} | {:error, Ecto.Changeset.t()}
  def create(attrs) do
    %Category{}
    |> Category.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Gets a category by its external ID and workspace ID with options.

  Returns the category if it exists, or `nil` if not found.

  ## Options

  The `:preload` option accepts a list of associations to preload. For example:

  - `[preload: [:envelopes]]` - preloads only envelopes

  ## Examples

      iex> get_by_external_id_and_workspace_id("abcd-1234", 1, preload: [:envelopes])
      %Category{envelopes: [...]}

      iex> get_by_external_id_and_workspace_id("non-existent-id", 1, preload: [:envelopes])
      nil

  """
  @spec get_by_external_id_and_workspace_id(Ecto.UUID.t(), integer(), get_options()) :: Category.t() | nil
  def get_by_external_id_and_workspace_id(external_id, workspace_id, opts \\ []) do
    external_id
    |> CategoryQuery.by_external_id()
    |> CategoryQuery.by_workspace_id(workspace_id)
    |> Repo.one()
    |> Utilities.maybe_preload(opts)
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
      {:ok, Utilities.maybe_preload(updated_category, opts)}
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
  Gets the position of the first category in a workspace (ordered by position).

  Returns the position as a string, or nil if no categories exist.

  ## Examples

      iex> get_first_position(1)
      "g"

      iex> get_first_position(999)
      nil

  """
  @spec get_first_position(integer()) :: String.t() | nil
  def get_first_position(workspace_id) do
    workspace_id
    |> CategoryQuery.by_workspace_id()
    |> CategoryQuery.order_by_position()
    |> CategoryQuery.limit(1)
    |> CategoryQuery.select_position()
    |> Repo.one()
  end

  @doc """
  Gets a category by its ID.

  Returns the category if it exists, or an error tuple if not found.

  ## Options

  The `:preload` option accepts a list of associations to preload.

  ## Examples

      iex> fetch(1)
      {:ok, %Category{}}

      iex> fetch(1, preload: [:workspace])
      {:ok, %Category{workspace: %Workspace{}}}

      iex> fetch(999)
      {:error, :not_found}

  """
  @spec fetch(integer(), get_options()) :: {:ok, Category.t()} | {:error, :not_found}
  def fetch(id, opts \\ []) do
    id
    |> CategoryQuery.by_id()
    |> Repo.one()
    |> case do
      nil ->
        {:error, :not_found}

      category ->
        {:ok, Utilities.maybe_preload(category, opts)}
    end
  end

  @doc """
  Gets multiple categories by their external IDs.

  Returns a list of categories that match the given external IDs.

  ## Options

  The `:preload` option accepts a list of associations to preload.

  ## Examples

      iex> list_by_external_ids(["id1", "id2", "id3"])
      [%Category{}, %Category{}]

      iex> list_by_external_ids(["id1", "id2"], preload: [:workspace])
      [%Category{workspace: %Workspace{}}, %Category{workspace: %Workspace{}}]

  """
  @spec list_by_external_ids([Ecto.UUID.t()], list_options()) :: [Category.t()]
  def list_by_external_ids(external_ids, opts \\ []) when is_list(external_ids) do
    external_ids
    |> CategoryQuery.by_external_ids()
    |> Repo.all()
    |> Utilities.maybe_preload(opts)
  end
end

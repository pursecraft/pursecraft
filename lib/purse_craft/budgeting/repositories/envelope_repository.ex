defmodule PurseCraft.Budgeting.Repositories.EnvelopeRepository do
  @moduledoc """
  Repository for `Envelope`.
  """

  alias PurseCraft.Budgeting.Queries.EnvelopeQuery
  alias PurseCraft.Budgeting.Schemas.Envelope
  alias PurseCraft.Repo
  alias PurseCraft.Types

  @type get_option :: {:preload, Types.preload()}
  @type get_options :: [get_option()]

  @type create_attrs :: %{
          optional(:name) => String.t(),
          required(:category_id) => integer(),
          required(:position) => String.t()
        }

  @type update_attrs :: %{
          optional(:name) => String.t()
        }

  @doc """
  Creates an envelope for a category.

  ## Examples

      iex> create(%{name: "Groceries", category_id: 1})
      {:ok, %Envelope{}}

      iex> create(%{name: "", category_id: 1})
      {:error, %Ecto.Changeset{}}

  """
  @spec create(create_attrs()) :: {:ok, Envelope.t()} | {:error, Ecto.Changeset.t()}
  def create(attrs) do
    %Envelope{}
    |> Envelope.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Gets an envelope by its external ID and book ID with options.

  Returns the envelope if it exists, or `nil` if not found.

  ## Options

  The `:preload` option accepts a list of associations to preload. For example:

  - `[preload: [:category]]` - preloads only category

  ## Examples

      iex> get_by_external_id_and_book_id("abcd-1234", 1, preload: [:category])
      %Envelope{category: %Category{}}

      iex> get_by_external_id_and_book_id("non-existent-id", 1, preload: [:category])
      nil

  """
  @spec get_by_external_id_and_book_id(Ecto.UUID.t(), integer(), get_options()) :: Envelope.t() | nil
  def get_by_external_id_and_book_id(external_id, book_id, opts \\ []) do
    external_id
    |> EnvelopeQuery.by_external_id()
    |> EnvelopeQuery.by_book_id(book_id)
    |> Repo.one()
    |> case do
      nil ->
        nil

      envelope ->
        preloads = Keyword.get(opts, :preload, [])
        if preloads == [], do: envelope, else: Repo.preload(envelope, preloads)
    end
  end

  @doc """
  Updates an envelope with the given attributes.

  ## Examples

      iex> update(envelope, %{name: "Updated Name"})
      {:ok, %Envelope{}}

      iex> update(envelope, %{name: ""})
      {:error, %Ecto.Changeset{}}

  """
  @spec update(Envelope.t(), update_attrs()) :: {:ok, Envelope.t()} | {:error, Ecto.Changeset.t()}
  def update(envelope, attrs) do
    envelope
    |> Envelope.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes an envelope.

  ## Examples

      iex> delete(%Envelope{})
      {:ok, %Envelope{}}

  """
  @spec delete(Envelope.t()) :: {:ok, Envelope.t()} | {:error, Ecto.Changeset.t()}
  def delete(%Envelope{} = envelope) do
    Repo.delete(envelope)
  end

  @doc """
  Updates the position and optionally category of an envelope.

  ## Examples

      iex> update_position(envelope, "m", 1)
      {:ok, %Envelope{position: "m", category_id: 1}}

      iex> update_position(envelope, "ABC", 1)
      {:error, %Ecto.Changeset{}}

  """
  @spec update_position(Envelope.t(), String.t(), integer()) :: {:ok, Envelope.t()} | {:error, Ecto.Changeset.t()}
  def update_position(envelope, new_position, category_id) do
    envelope
    |> Envelope.position_changeset(%{position: new_position, category_id: category_id})
    |> Repo.update()
  end

  @doc """
  Gets multiple envelopes by their external IDs.

  Returns a list of envelopes that match the given external IDs.

  ## Options

  The `:preload` option accepts a list of associations to preload.

  ## Examples

      iex> list_by_external_ids(["id1", "id2", "id3"])
      [%Envelope{}, %Envelope{}]

      iex> list_by_external_ids(["id1", "id2"], preload: [:category])
      [%Envelope{category: %Category{}}, %Envelope{category: %Category{}}]

  """
  @spec list_by_external_ids([Ecto.UUID.t()], get_options()) :: [Envelope.t()]
  def list_by_external_ids(external_ids, opts \\ []) when is_list(external_ids) do
    envelopes =
      external_ids
      |> EnvelopeQuery.by_external_ids()
      |> Repo.all()

    preloads = Keyword.get(opts, :preload, [])
    if preloads == [], do: envelopes, else: Repo.preload(envelopes, preloads)
  end

  @doc """
  Gets the first position in a category for positioning new envelopes.

  Returns the position of the first envelope in the category, or `nil` if the category has no envelopes.

  ## Examples

      iex> get_first_position(1)
      "m"

      iex> get_first_position(999)
      nil

  """
  @spec get_first_position(integer()) :: String.t() | nil
  def get_first_position(category_id) do
    category_id
    |> EnvelopeQuery.by_category_id()
    |> EnvelopeQuery.order_by_position()
    |> EnvelopeQuery.limit(1)
    |> EnvelopeQuery.select_position()
    |> Repo.one()
  end
end

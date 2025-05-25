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
          required(:category_id) => integer()
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
end

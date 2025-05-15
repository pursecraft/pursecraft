defmodule PurseCraft.Budgeting.Schemas.Category do
  @moduledoc """
  A `Category` represents a group of envelopes in a `Book`.

  Categories help to organize envelopes into logical groupings.
  """

  use Ecto.Schema

  import Ecto.Changeset

  alias Ecto.Association.NotLoaded
  alias PurseCraft.Budgeting.Schemas.Book
  alias PurseCraft.Budgeting.Schemas.Envelope

  @type t :: %__MODULE__{
          __meta__: Ecto.Schema.Metadata.t(),
          id: integer() | nil,
          name: String.t() | nil,
          external_id: Ecto.UUID.t() | nil,
          position: integer() | nil,
          book: Book.t() | NotLoaded.t() | nil,
          book_id: integer() | nil,
          envelopes: [Envelope.t()] | NotLoaded.t() | nil,
          inserted_at: DateTime.t() | nil,
          updated_at: DateTime.t() | nil
        }

  @type changeset_attrs :: %{
          optional(:name) => String.t(),
          optional(:book_id) => integer(),
          optional(:position) => integer()
        }

  schema "categories" do
    field :name, :string
    field :external_id, Ecto.UUID, autogenerate: true
    field :position, :integer, default: 0

    belongs_to :book, Book
    has_many :envelopes, Envelope

    timestamps(type: :utc_datetime)
  end

  @doc false
  @spec changeset(t(), changeset_attrs()) :: Ecto.Changeset.t()
  def changeset(category, attrs) do
    category
    |> cast(attrs, [:name, :book_id, :position])
    |> validate_required([:name, :book_id])
  end

  @doc """
  Creates a changeset for updating only the position of a category.

  ## Examples

      iex> position_changeset(%Category{position: 5}, 3)
      #Ecto.Changeset<valid?=true, changes=%{position: 3}>

  """
  @spec position_changeset(t(), integer()) :: Ecto.Changeset.t()
  def position_changeset(category, position) when is_integer(position) do
    cast(category, %{position: position}, [:position])
  end
end

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
          position: String.t() | nil,
          external_id: Ecto.UUID.t() | nil,
          book: Book.t() | NotLoaded.t() | nil,
          book_id: integer() | nil,
          envelopes: [Envelope.t()] | NotLoaded.t() | nil,
          inserted_at: DateTime.t() | nil,
          updated_at: DateTime.t() | nil
        }

  @type changeset_attrs :: %{
          optional(:name) => String.t(),
          optional(:position) => String.t(),
          optional(:book_id) => integer()
        }

  schema "categories" do
    field :name, :string
    field :position, :string
    field :external_id, Ecto.UUID, autogenerate: true

    belongs_to :book, Book
    has_many :envelopes, Envelope, preload_order: [asc: :position]

    timestamps(type: :utc_datetime)
  end

  @doc false
  @spec changeset(t(), changeset_attrs()) :: Ecto.Changeset.t()
  def changeset(category, attrs) do
    category
    |> cast(attrs, [:name, :position, :book_id])
    |> validate_required([:name, :position, :book_id])
  end

  @doc false
  @spec position_changeset(t(), %{position: String.t()}) :: Ecto.Changeset.t()
  def position_changeset(category, attrs) do
    category
    |> cast(attrs, [:position])
    |> validate_required([:position])
    |> validate_format(:position, ~r/^[a-z]+$/, message: "must contain only lowercase letters")
    |> unique_constraint(:position, name: :categories_book_id_position_index)
  end
end

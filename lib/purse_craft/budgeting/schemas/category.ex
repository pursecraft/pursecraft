defmodule PurseCraft.Budgeting.Schemas.Category do
  @moduledoc """
  A `Category` represents a group of envelopes in a `Book`.

  Categories help to organize envelopes into logical groupings.
  """

  use Ecto.Schema

  alias Ecto.Association.NotLoaded
  alias PurseCraft.Budgeting.Schemas.Book
  alias PurseCraft.Budgeting.Schemas.Envelope

  @type t :: %__MODULE__{
          __meta__: Ecto.Schema.Metadata.t(),
          id: integer() | nil,
          name: String.t() | nil,
          external_id: Ecto.UUID.t() | nil,
          book: Book.t() | NotLoaded.t() | nil,
          book_id: integer() | nil,
          envelopes: [Envelope.t()] | NotLoaded.t() | nil,
          inserted_at: DateTime.t() | nil,
          updated_at: DateTime.t() | nil
        }

  @type changeset_attrs :: %{
          optional(:name) => String.t(),
          optional(:book_id) => integer()
        }

  schema "categories" do
    field :name, :string
    field :external_id, Ecto.UUID, autogenerate: true

    belongs_to :book, Book
    has_many :envelopes, Envelope

    timestamps(type: :utc_datetime)
  end
end

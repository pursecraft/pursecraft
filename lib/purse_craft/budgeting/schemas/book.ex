defmodule PurseCraft.Budgeting.Schemas.Book do
  @moduledoc """
  `Book` is the top-most level resource for Budgeting. This is where all
  resources related to budgeting are grouped under.
  """

  use Ecto.Schema
  import Ecto.Changeset

  @type t :: %__MODULE__{
          __meta__: Ecto.Schema.Metadata.t(),
          id: integer() | nil,
          name: String.t() | nil,
          inserted_at: DateTime.t() | nil,
          updated_at: DateTime.t() | nil
        }

  schema "books" do
    field :name, :string

    timestamps(type: :utc_datetime)
  end

  @doc false
  @spec changeset(t(), map()) :: Ecto.Changeset.t()
  def changeset(book, attrs) do
    book
    |> cast(attrs, [:name])
    |> validate_required([:name])
  end
end

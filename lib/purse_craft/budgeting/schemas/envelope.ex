defmodule PurseCraft.Budgeting.Schemas.Envelope do
  @moduledoc """
  An `Envelope` represents a budget allocation for a specific purpose.

  Envelopes belong to a `Category` and are used to track spending within the budget.
  """

  use Ecto.Schema

  import Ecto.Changeset

  alias PurseCraft.Budgeting.Schemas.Category

  @type t :: %__MODULE__{
          __meta__: Ecto.Schema.Metadata.t(),
          id: integer() | nil,
          name: String.t() | nil,
          external_id: Ecto.UUID.t() | nil,
          category: Category.t() | Ecto.Association.NotLoaded.t() | nil,
          category_id: integer() | nil,
          inserted_at: DateTime.t() | nil,
          updated_at: DateTime.t() | nil
        }

  @type changeset_attrs :: %{
          optional(:name) => String.t(),
          optional(:category_id) => integer()
        }

  schema "envelopes" do
    field :name, :string
    field :external_id, Ecto.UUID, autogenerate: true

    belongs_to :category, Category

    timestamps(type: :utc_datetime)
  end

  @doc false
  @spec changeset(t(), changeset_attrs()) :: Ecto.Changeset.t()
  def changeset(envelope, attrs) do
    envelope
    |> cast(attrs, [:name, :category_id])
    |> validate_required([:name, :category_id])
    |> foreign_key_constraint(:category_id)
  end
end

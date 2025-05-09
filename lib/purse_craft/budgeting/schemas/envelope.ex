defmodule PurseCraft.Budgeting.Schemas.Envelope do
  @moduledoc """
  An `Envelope` represents a budget allocation for a specific purpose.

  Envelopes belong to a `Category` and are used to track spending within the budget.
  """

  use Ecto.Schema

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
end

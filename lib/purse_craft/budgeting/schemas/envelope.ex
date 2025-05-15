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
          position: integer() | nil,
          category: Category.t() | Ecto.Association.NotLoaded.t() | nil,
          category_id: integer() | nil,
          inserted_at: DateTime.t() | nil,
          updated_at: DateTime.t() | nil
        }

  @type changeset_attrs :: %{
          optional(:name) => String.t(),
          optional(:category_id) => integer(),
          optional(:position) => integer()
        }

  schema "envelopes" do
    field :name, :string
    field :external_id, Ecto.UUID, autogenerate: true
    field :position, :integer, default: 0

    belongs_to :category, Category

    timestamps(type: :utc_datetime)
  end

  @doc """
  Creates a changeset for an envelope.

  ## Examples

      iex> changeset(%Envelope{}, %{name: "Groceries", category_id: 1})
      #Ecto.Changeset<valid?=true, ...>

      iex> changeset(%Envelope{}, %{})
      #Ecto.Changeset<valid?=false, errors=[name: {"can't be blank", ...}, category_id: {"can't be blank", ...}]>

  """
  @spec changeset(t(), changeset_attrs()) :: Ecto.Changeset.t()
  def changeset(envelope, attrs) do
    envelope
    |> cast(attrs, [:name, :category_id, :position])
    |> validate_required([:name, :category_id])
  end

  @doc """
  Creates a changeset for updating only the position of an envelope.

  ## Examples

      iex> position_changeset(%Envelope{position: 5}, 3)
      #Ecto.Changeset<valid?=true, changes=%{position: 3}>

  """
  @spec position_changeset(t(), integer()) :: Ecto.Changeset.t()
  def position_changeset(envelope, position) when is_integer(position) do
    cast(envelope, %{position: position}, [:position])
  end
end

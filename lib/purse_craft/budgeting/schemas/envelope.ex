defmodule PurseCraft.Budgeting.Schemas.Envelope do
  @moduledoc """
  An `Envelope` represents a budget allocation for a specific purpose.

  Envelopes belong to a `Category` and are used to track spending within the budget.
  """

  use Ecto.Schema

  import Ecto.Changeset

  alias PurseCraft.Budgeting.Schemas.Category
  alias PurseCraft.Utilities.EncryptedBinary
  alias PurseCraft.Utilities.HashedHMAC

  @type t :: %__MODULE__{
          __meta__: Ecto.Schema.Metadata.t(),
          id: integer() | nil,
          name: String.t() | nil,
          name_hash: binary() | nil,
          external_id: Ecto.UUID.t() | nil,
          position: String.t() | nil,
          category: Category.t() | Ecto.Association.NotLoaded.t() | nil,
          category_id: integer() | nil,
          inserted_at: DateTime.t() | nil,
          updated_at: DateTime.t() | nil
        }

  @type changeset_attrs :: %{
          optional(:name) => String.t(),
          optional(:category_id) => integer(),
          optional(:position) => String.t()
        }

  schema "envelopes" do
    field :name, EncryptedBinary
    field :name_hash, HashedHMAC
    field :external_id, Ecto.UUID, autogenerate: true
    field :position, :string

    belongs_to :category, Category

    timestamps(type: :utc_datetime)
  end

  @doc false
  @spec changeset(t(), changeset_attrs()) :: Ecto.Changeset.t()
  def changeset(envelope, attrs) do
    envelope
    |> cast(attrs, [:name, :category_id, :position])
    |> put_hashed_fields()
    |> validate_required([:name, :category_id, :position])
    |> unique_constraint(:position, name: :envelopes_category_id_position_index)
  end

  @doc false
  @spec position_changeset(t(), changeset_attrs()) :: Ecto.Changeset.t()
  def position_changeset(envelope, attrs) do
    envelope
    |> cast(attrs, [:position, :category_id])
    |> validate_required([:position, :category_id])
    |> validate_format(:position, ~r/^[a-z]+$/, message: "must contain only lowercase letters")
    |> unique_constraint(:position, name: :envelopes_category_id_position_index)
  end

  defp put_hashed_fields(changeset) do
    case get_field(changeset, :name) do
      nil ->
        changeset

      name when is_binary(name) ->
        put_change(changeset, :name_hash, name)

      _other ->
        # coveralls-ignore-next-line
        changeset
    end
  end
end

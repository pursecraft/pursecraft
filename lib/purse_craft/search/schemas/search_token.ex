defmodule PurseCraft.Search.Schemas.SearchToken do
  @moduledoc false
  use Ecto.Schema

  import Ecto.Changeset

  @valid_entity_types [
    "account",
    "category",
    "envelope",
    "workspace"
  ]

  @type t :: %__MODULE__{
          id: integer() | nil,
          entity_type: String.t(),
          entity_id: integer(),
          field_name: String.t(),
          token_hash: binary(),
          workspace_id: integer(),
          algorithm_version: integer(),
          token_length: integer(),
          inserted_at: DateTime.t() | nil,
          updated_at: DateTime.t() | nil
        }

  schema "search_tokens" do
    field :entity_type, :string
    field :entity_id, :integer
    field :field_name, :string
    field :token_hash, PurseCraft.Utilities.SearchToken
    field :algorithm_version, :integer, default: 1
    field :token_length, :integer, default: 3

    belongs_to :workspace, PurseCraft.Core.Schemas.Workspace

    timestamps(type: :utc_datetime)
  end

  @spec valid_entity_types() :: list(String.t())
  def valid_entity_types, do: @valid_entity_types

  @spec changeset(t(), map()) :: Ecto.Changeset.t()
  def changeset(search_token, attrs) do
    search_token
    |> cast(attrs, [
      :entity_type,
      :entity_id,
      :field_name,
      :token_hash,
      :workspace_id,
      :algorithm_version,
      :token_length
    ])
    |> validate_required([:entity_type, :entity_id, :field_name, :token_hash, :workspace_id])
    |> validate_inclusion(:entity_type, @valid_entity_types)
    |> validate_number(:algorithm_version, greater_than: 0)
    |> validate_number(:token_length, greater_than: 0)
    |> foreign_key_constraint(:workspace_id)
  end
end

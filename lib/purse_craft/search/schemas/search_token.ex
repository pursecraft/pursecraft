defmodule PurseCraft.Search.Schemas.SearchToken do
  @moduledoc false
  use Ecto.Schema

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
end

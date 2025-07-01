defmodule PurseCraft.Core.Schemas.Workspace do
  @moduledoc """
  A `Workspace` represents the user's budget. This is also the
  umbrella table where everything about budgets are grouped
  under.
  """

  use Ecto.Schema

  import Ecto.Changeset

  alias PurseCraft.Budgeting.Schemas.Category
  alias PurseCraft.Core.Schemas.WorkspaceUser
  alias PurseCraft.Identity.Schemas.User
  alias PurseCraft.Utilities
  alias PurseCraft.Utilities.EncryptedBinary
  alias PurseCraft.Utilities.HashedHMAC

  @type t :: %__MODULE__{
          __meta__: Ecto.Schema.Metadata.t(),
          id: integer() | nil,
          name: String.t() | nil,
          name_hash: binary() | nil,
          external_id: Ecto.UUID.t() | nil,
          categories: [Category.t()] | Ecto.Association.NotLoaded.t() | nil,
          inserted_at: DateTime.t() | nil,
          updated_at: DateTime.t() | nil
        }

  @type changeset_attrs :: %{
          optional(:name) => String.t()
        }

  schema "workspaces" do
    field :external_id, Ecto.UUID, autogenerate: true
    field :name, EncryptedBinary
    field :name_hash, HashedHMAC

    many_to_many :users, User, join_through: WorkspaceUser
    has_many :workspace_users, WorkspaceUser
    has_many :categories, Category

    timestamps(type: :utc_datetime)
  end

  @doc false
  @spec changeset(t(), changeset_attrs()) :: Ecto.Changeset.t()
  def changeset(workspace, attrs) do
    workspace
    |> cast(attrs, [:name])
    |> Utilities.put_hashed_field(:name)
    |> validate_required([:name])
  end
end

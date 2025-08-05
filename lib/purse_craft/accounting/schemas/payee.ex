defmodule PurseCraft.Accounting.Schemas.Payee do
  @moduledoc """
  A `Payee` represents an entity that receives or sends money in a `Workspace`.

  Payees are used to categorize and track transactions by the recipient or sender
  of funds, enabling better transaction organization and reporting.
  """

  use Ecto.Schema

  import Ecto.Changeset

  alias Ecto.Association.NotLoaded
  alias PurseCraft.Core.Schemas.Workspace
  alias PurseCraft.Utilities
  alias PurseCraft.Utilities.EncryptedBinary
  alias PurseCraft.Utilities.HashedHMAC

  @type t :: %__MODULE__{
          __meta__: Ecto.Schema.Metadata.t(),
          id: integer() | nil,
          name: String.t() | nil,
          name_hash: binary() | nil,
          external_id: Ecto.UUID.t() | nil,
          workspace: Workspace.t() | NotLoaded.t() | nil,
          workspace_id: integer() | nil,
          inserted_at: DateTime.t() | nil,
          updated_at: DateTime.t() | nil
        }

  @type changeset_attrs :: %{
          optional(:name) => String.t(),
          optional(:workspace_id) => integer()
        }

  schema "payees" do
    field :name, EncryptedBinary
    field :name_hash, HashedHMAC
    field :external_id, Ecto.UUID, autogenerate: true

    belongs_to :workspace, Workspace

    timestamps(type: :utc_datetime)
  end

  @doc """
  Creates a changeset for payee creation and updates.

  The name field is required. Workspace_id is required for creation but not for updates.

  ## Examples

      iex> Payee.changeset(%Payee{}, %{
      ...>   name: "Grocery Store",
      ...>   workspace_id: 123
      ...> })
      %Ecto.Changeset{valid?: true}

  """
  @spec changeset(t(), changeset_attrs()) :: Ecto.Changeset.t()
  def changeset(payee, attrs) do
    payee
    |> cast(attrs, [:name, :workspace_id])
    |> Utilities.put_hashed_field(:name)
    |> validate_required([:name, :workspace_id])
    |> unique_constraint(:external_id, name: :payees_external_id_index)
    |> unique_constraint(:name_hash, name: :payees_name_hash_workspace_id_index)
    |> foreign_key_constraint(:workspace_id)
  end
end

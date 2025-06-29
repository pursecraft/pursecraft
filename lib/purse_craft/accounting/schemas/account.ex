defmodule PurseCraft.Accounting.Schemas.Account do
  @moduledoc """
  An `Account` represents a financial account (cash, credit, loan, asset, or liability) in a `Workspace`.

  Accounts track balances and transactions for different types of financial instruments.
  They can be on-budget (affecting envelope allocations) or off-budget (tracking only).
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
          account_type: String.t() | nil,
          account_type_hash: binary() | nil,
          description: String.t() | nil,
          description_hash: binary() | nil,
          position: String.t() | nil,
          external_id: Ecto.UUID.t() | nil,
          workspace: Workspace.t() | NotLoaded.t() | nil,
          workspace_id: integer() | nil,
          closed_at: DateTime.t() | nil,
          inserted_at: DateTime.t() | nil,
          updated_at: DateTime.t() | nil
        }

  @type create_changeset_attrs :: %{
          optional(:name) => String.t(),
          optional(:account_type) => String.t(),
          optional(:workspace_id) => integer(),
          optional(:position) => String.t(),
          optional(:description) => String.t()
        }

  @type update_changeset_attrs :: %{
          optional(:name) => String.t(),
          optional(:description) => String.t()
        }

  @type position_changeset_attrs :: %{
          required(:position) => String.t()
        }

  @type close_changeset_attrs :: %{
          required(:closed_at) => DateTime.t()
        }

  # Account type constants
  @account_types [
    "checking",
    "savings",
    "cash",
    "credit_card",
    "line_of_credit",
    "mortgage",
    "auto_loan",
    "student_loan",
    "personal_loan",
    "medical_debt",
    "other_debt",
    "asset",
    "liability"
  ]

  # coveralls-ignore-start
  schema "accounts" do
    field :name, EncryptedBinary
    field :name_hash, HashedHMAC
    field :account_type, EncryptedBinary
    field :account_type_hash, HashedHMAC
    field :description, EncryptedBinary
    field :description_hash, HashedHMAC
    field :position, :string
    field :external_id, Ecto.UUID, autogenerate: true
    field :closed_at, :utc_datetime

    belongs_to :workspace, Workspace

    timestamps(type: :utc_datetime)
  end

  @doc """
  Creates a changeset for account creation.

  All required fields must be provided: name, account_type, workspace_id, and position.
  The description field is optional.

  ## Examples

      iex> Account.create_changeset(%Account{}, %{
      ...>   name: "My Checking Account",
      ...>   account_type: "checking",
      ...>   workspace_id: 123,
      ...>   position: "a"
      ...> })
      %Ecto.Changeset{valid?: true}

  """
  @spec create_changeset(t(), create_changeset_attrs()) :: Ecto.Changeset.t()
  def create_changeset(account, attrs) do
    account
    |> cast(attrs, [:name, :account_type, :description, :position, :workspace_id])
    |> Utilities.put_hashed_field([:name, :account_type, :description])
    |> validate_required([:name, :account_type, :position, :workspace_id])
    |> validate_inclusion(:account_type, @account_types)
    |> validate_format(:position, ~r/^[a-z]+$/, message: "must contain only lowercase letters")
    |> unique_constraint(:external_id, name: :accounts_external_id_index)
    |> unique_constraint(:position, name: :accounts_workspace_id_position_index)
    |> foreign_key_constraint(:workspace_id)
  end

  @doc """
  Creates a changeset for account updates.

  Only name and description can be updated. Account type, position, and workspace_id
  cannot be changed after creation.

  ## Examples

      iex> Account.update_changeset(account, %{name: "Updated Account Name"})
      %Ecto.Changeset{valid?: true}

  """
  @spec update_changeset(t(), update_changeset_attrs()) :: Ecto.Changeset.t()
  def update_changeset(account, attrs) do
    account
    |> cast(attrs, [:name, :description])
    |> Utilities.put_hashed_field([:name, :description])
    |> validate_required([:name])
  end

  @doc """
  Creates a changeset for account closure.

  Sets the closed_at timestamp to mark the account as closed.

  ## Examples

      iex> Account.close_changeset(account, %{closed_at: DateTime.utc_now()})
      %Ecto.Changeset{valid?: true}

  """
  @spec close_changeset(t(), close_changeset_attrs()) :: Ecto.Changeset.t()
  def close_changeset(account, attrs) do
    account
    |> cast(attrs, [:closed_at])
    |> validate_required([:closed_at])
  end

  @doc """
  Creates a changeset for position updates.

  Used for drag-and-drop reordering functionality.

  ## Examples

      iex> Account.position_changeset(account, %{position: "b"})
      %Ecto.Changeset{valid?: true}

  """
  @spec position_changeset(t(), position_changeset_attrs()) :: Ecto.Changeset.t()
  def position_changeset(account, attrs) do
    account
    |> cast(attrs, [:position])
    |> validate_required([:position])
    |> validate_format(:position, ~r/^[a-z]+$/, message: "must contain only lowercase letters")
    |> unique_constraint(:position, name: :accounts_workspace_id_position_index)
  end

  @doc """
  Returns all valid account types.

  ## Examples

      iex> Account.account_types()
      ["checking", "savings", "cash", ...]

  """
  @spec account_types() :: [String.t()]
  def account_types, do: @account_types
  # coveralls-ignore-stop
end

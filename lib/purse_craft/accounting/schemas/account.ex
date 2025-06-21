defmodule PurseCraft.Accounting.Schemas.Account do
  @moduledoc """
  Represents a financial account within a book, such as checking,
  savings, credit cards, loans, and tracking accounts.
  """

  use Ecto.Schema

  import Ecto.Changeset

  alias PurseCraft.Identity.Schemas.Book
  alias PurseCraft.Utilities.EncryptedBinary
  alias PurseCraft.Utilities.HashedHMAC

  @account_types [
    "checking",
    "savings",
    "credit_card",
    "cash",
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
          book: Book.t() | Ecto.Association.NotLoaded.t() | nil,
          book_id: integer() | nil,
          closed_at: DateTime.t() | nil,
          inserted_at: DateTime.t() | nil,
          updated_at: DateTime.t() | nil
        }

  @type changeset_attrs :: %{
          optional(:name) => String.t(),
          optional(:account_type) => String.t(),
          optional(:description) => String.t(),
          optional(:position) => String.t(),
          optional(:book_id) => integer(),
          optional(:closed_at) => DateTime.t()
        }

  schema "accounts" do
    field :external_id, Ecto.UUID, autogenerate: true
    field :name, EncryptedBinary
    field :name_hash, HashedHMAC
    field :account_type, EncryptedBinary
    field :account_type_hash, HashedHMAC
    field :description, EncryptedBinary
    field :description_hash, HashedHMAC
    field :position, :string
    field :closed_at, :utc_datetime

    belongs_to :book, Book

    timestamps(type: :utc_datetime)
  end

  @doc """
  Changeset for creating a new account.
  """
  @spec create_changeset(t(), changeset_attrs()) :: Ecto.Changeset.t()
  def create_changeset(account, attrs) do
    account
    |> cast(attrs, [:name, :account_type, :description, :position, :book_id])
    |> put_hashed_fields()
    |> validate_required([:name, :account_type, :position, :book_id])
    |> validate_inclusion(:account_type, @account_types)
    |> validate_format(:position, ~r/^[a-z]+$/, message: "must contain only lowercase letters")
    |> foreign_key_constraint(:book_id)
    |> unique_constraint(:external_id)
  end

  @doc """
  Changeset for updating an existing account (name and description only).
  """
  @spec update_changeset(t(), changeset_attrs()) :: Ecto.Changeset.t()
  def update_changeset(account, attrs) do
    account
    |> cast(attrs, [:name, :description])
    |> put_hashed_fields()
    |> validate_required([:name])
  end

  @doc """
  Changeset for closing an account.
  """
  @spec close_changeset(t(), %{closed_at: DateTime.t()}) :: Ecto.Changeset.t()
  def close_changeset(account, attrs) do
    account
    |> cast(attrs, [:closed_at])
    |> validate_required([:closed_at])
  end

  @doc """
  Changeset for updating account position during reordering.
  """
  @spec position_changeset(t(), %{position: String.t()}) :: Ecto.Changeset.t()
  def position_changeset(account, attrs) do
    account
    |> cast(attrs, [:position])
    |> validate_required([:position])
    |> validate_format(:position, ~r/^[a-z]+$/, message: "must contain only lowercase letters")
  end

  @doc """
  Returns the list of valid account types.
  """
  @spec account_types() :: [String.t()]
  def account_types, do: @account_types

  defp put_hashed_fields(changeset) do
    changeset
    |> put_name_hash()
    |> put_account_type_hash()
    |> put_description_hash()
  end

  defp put_name_hash(changeset) do
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

  defp put_account_type_hash(changeset) do
    case get_field(changeset, :account_type) do
      nil ->
        changeset

      account_type when is_binary(account_type) ->
        put_change(changeset, :account_type_hash, account_type)

      _other ->
        # coveralls-ignore-next-line
        changeset
    end
  end

  defp put_description_hash(changeset) do
    case get_field(changeset, :description) do
      nil ->
        changeset

      description when is_binary(description) ->
        put_change(changeset, :description_hash, description)

      _other ->
        # coveralls-ignore-next-line
        changeset
    end
  end
end

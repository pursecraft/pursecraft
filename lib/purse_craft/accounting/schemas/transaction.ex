defmodule PurseCraft.Accounting.Schemas.Transaction do
  @moduledoc """
  A `Transaction` represents a financial transaction that affects an `Account` within a `Workspace`.

  Transactions use dual-column encryption for memo fields and support the double-entry
  accounting system with positive/negative amounts. Each transaction can be linked to
  another transaction for transfer functionality (Move Money).
  """

  use Ecto.Schema

  alias Ecto.Association.NotLoaded
  alias PurseCraft.Accounting.Schemas.Account
  alias PurseCraft.Accounting.Schemas.Payee
  alias PurseCraft.Accounting.Schemas.TransactionLine
  alias PurseCraft.Core.Schemas.Workspace
  alias PurseCraft.Utilities.EncryptedBinary
  alias PurseCraft.Utilities.HashedHMAC

  @type t :: %__MODULE__{
          __meta__: Ecto.Schema.Metadata.t(),
          id: integer() | nil,
          external_id: Ecto.UUID.t() | nil,
          date: Date.t() | nil,
          amount: integer() | nil,
          memo: String.t() | nil,
          memo_hash: binary() | nil,
          cleared: boolean() | nil,
          reconciled_at: DateTime.t() | nil,
          linked_transaction_id: integer() | nil,
          account: Account.t() | NotLoaded.t() | nil,
          account_id: integer() | nil,
          payee: Payee.t() | NotLoaded.t() | nil,
          payee_id: integer() | nil,
          workspace: Workspace.t() | NotLoaded.t() | nil,
          workspace_id: integer() | nil,
          linked_transaction: t() | NotLoaded.t() | nil,
          transaction_lines: [TransactionLine.t()] | NotLoaded.t(),
          inserted_at: DateTime.t() | nil,
          updated_at: DateTime.t() | nil
        }

  schema "transactions" do
    field :external_id, Ecto.UUID, autogenerate: true
    field :date, :date
    field :amount, :integer, default: 0
    field :memo, EncryptedBinary
    field :memo_hash, HashedHMAC
    field :cleared, :boolean, default: false
    field :reconciled_at, :utc_datetime

    belongs_to :account, Account
    belongs_to :payee, Payee
    belongs_to :workspace, Workspace
    belongs_to :linked_transaction, __MODULE__, foreign_key: :linked_transaction_id

    has_many :transaction_lines, TransactionLine

    timestamps(type: :utc_datetime)
  end
end

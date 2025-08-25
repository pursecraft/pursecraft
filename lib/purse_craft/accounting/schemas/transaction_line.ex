defmodule PurseCraft.Accounting.Schemas.TransactionLine do
  @moduledoc """
  A `TransactionLine` represents a single line item within a `Transaction`, enabling split transactions.

  Each line can be allocated to a specific `Envelope` for budgeting purposes, with optional
  line-specific payee and memo information. Lines with null envelope_id flow to "Ready to Assign".
  """

  use Ecto.Schema

  alias Ecto.Association.NotLoaded
  alias PurseCraft.Accounting.Schemas.Payee
  alias PurseCraft.Accounting.Schemas.Transaction
  alias PurseCraft.Budgeting.Schemas.Envelope
  alias PurseCraft.Utilities.EncryptedBinary
  alias PurseCraft.Utilities.HashedHMAC

  @type t :: %__MODULE__{
          __meta__: Ecto.Schema.Metadata.t(),
          id: integer() | nil,
          external_id: Ecto.UUID.t() | nil,
          amount: integer() | nil,
          memo: String.t() | nil,
          memo_hash: binary() | nil,
          transaction: Transaction.t() | NotLoaded.t() | nil,
          transaction_id: integer() | nil,
          envelope: Envelope.t() | NotLoaded.t() | nil,
          envelope_id: integer() | nil,
          payee: Payee.t() | NotLoaded.t() | nil,
          payee_id: integer() | nil,
          inserted_at: DateTime.t() | nil,
          updated_at: DateTime.t() | nil
        }

  schema "transaction_lines" do
    field :external_id, Ecto.UUID, autogenerate: true
    field :amount, :integer, default: 0
    field :memo, EncryptedBinary
    field :memo_hash, HashedHMAC

    belongs_to :transaction, Transaction
    belongs_to :envelope, Envelope
    belongs_to :payee, Payee

    timestamps(type: :utc_datetime)
  end
end

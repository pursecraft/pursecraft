defmodule PurseCraft.Accounting.Schemas.User do
  @moduledoc """
  A `User` within the `Accounting` context.
  """

  use Ecto.Schema

  alias PurseCraft.Utilities.EncryptedBinary
  alias PurseCraft.Utilities.HashedHMAC

  @type t :: %__MODULE__{
          __meta__: Ecto.Schema.Metadata.t(),
          id: integer() | nil,
          email: String.t() | nil,
          email_hash: binary() | nil,
          inserted_at: DateTime.t() | nil,
          updated_at: DateTime.t() | nil
        }

  schema "users" do
    field :email, EncryptedBinary
    field :email_hash, HashedHMAC

    timestamps(type: :utc_datetime)
  end
end

defmodule PurseCraft.Utilities.EncryptedBinary do
  @moduledoc """
  Local Ecto type used for encrypting sensitive columns.
  """

  use Cloak.Ecto.Binary, vault: PurseCraft.Vault
end

defmodule PurseCraft.Identity.Events.AllUserTokensDeleted do
  @moduledoc """
  Event emitted when all of a user's tokens are deleted.
  """
  @derive Jason.Encoder
  defstruct [:user_uuid, :token_type, :except_token, :timestamp]
end

defmodule PurseCraft.Identity.Events.AllUserTokensDeleted do
  @moduledoc false
  @derive Jason.Encoder
  defstruct [:user_uuid, :token_type, :except_token]
end

defmodule PurseCraft.Identity.Events.AllUserTokensDeleted do
  @moduledoc false
  defstruct [:user_uuid, :token_type, :except_token, :timestamp]
end

defmodule PurseCraft.Identity.Commands.DeleteAllUserTokens do
  @moduledoc false
  defstruct [:user_uuid, :token_type, :except_token]
end

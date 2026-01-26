defmodule PurseCraft.Identity.Commands.CreateSessionToken do
  @moduledoc false
  defstruct [:user_uuid, :user_agent, :ip_address, :token_type]
end

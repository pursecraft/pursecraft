defmodule PurseCraft.Identity.Commands.CreateSessionToken do
  @moduledoc """
  Command to create a session token after successful authentication.
  """
  defstruct [:user_uuid, :user_agent, :ip_address]
end

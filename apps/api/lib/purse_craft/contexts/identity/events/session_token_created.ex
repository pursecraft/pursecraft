defmodule PurseCraft.Identity.Events.SessionTokenCreated do
  @moduledoc """
  Event emitted when a session token is created.
  """
  @derive Jason.Encoder
  defstruct [:token, :user_uuid, :user_agent, :ip_address, :expires_at, :timestamp]
end

defmodule PurseCraft.Identity.Events.SessionTokenCreated do
  @moduledoc false
  defstruct [:token, :user_uuid, :user_agent, :ip_address, :expires_at, :timestamp]
end

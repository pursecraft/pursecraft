defmodule PurseCraft.Identity.Events.SessionTokenCreated do
  @moduledoc false
  @derive Jason.Encoder
  defstruct [:token, :user_uuid, :user_agent, :ip_address, :expires_at]
end

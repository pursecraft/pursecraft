defmodule PurseCraft.Identity.Events.MagicLinkRequested do
  @moduledoc false
  defstruct [:token, :user_uuid, :email, :expires_at, :timestamp]
end

defmodule PurseCraft.Identity.Events.MagicLinkRequested do
  @moduledoc """
  Event emitted when a magic link is requested.
  """
  @derive Jason.Encoder
  defstruct [:token, :user_uuid, :email, :expires_at, :timestamp]
end

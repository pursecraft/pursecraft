defmodule PurseCraft.Identity.Events.MagicLinkRequested do
  @moduledoc false
  @derive Jason.Encoder
  defstruct [:token, :user_uuid, :email, :expires_at]
end

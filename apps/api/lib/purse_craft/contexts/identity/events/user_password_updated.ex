defmodule PurseCraft.Identity.Events.UserPasswordUpdated do
  @moduledoc false
  @derive Jason.Encoder
  defstruct [:user_uuid, :timestamp]
end

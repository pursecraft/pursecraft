defmodule PurseCraft.Identity.Events.UserPasswordCreated do
  @moduledoc false
  defstruct [:user_uuid, :hashed_password, :timestamp]
end

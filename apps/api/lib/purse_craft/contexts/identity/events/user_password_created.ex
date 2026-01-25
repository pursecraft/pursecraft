defmodule PurseCraft.Identity.Events.UserPasswordCreated do
  @moduledoc false
  @derive Jason.Encoder
  defstruct [:user_uuid, :hashed_password]
end

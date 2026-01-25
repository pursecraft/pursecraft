defmodule PurseCraft.Identity.Events.UserRegistered do
  @moduledoc false
  @derive Jason.Encoder
  defstruct [:user_uuid, :email, :hashed_password, :confirmed_at]
end

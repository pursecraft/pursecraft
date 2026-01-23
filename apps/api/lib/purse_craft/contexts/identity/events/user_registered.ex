defmodule PurseCraft.Identity.Events.UserRegistered do
  @moduledoc false
  defstruct [:user_uuid, :email, :hashed_password, :confirmed_at, :timestamp]
end

defmodule PurseCraft.Identity.Events.UserRegistered do
  @moduledoc """
  Event emitted when a user is registered.
  """
  @derive Jason.Encoder
  defstruct [:user_uuid, :email, :hashed_password, :confirmed_at, :timestamp]
end

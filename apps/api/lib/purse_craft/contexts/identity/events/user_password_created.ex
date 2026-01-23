defmodule PurseCraft.Identity.Events.UserPasswordCreated do
  @moduledoc """
  Event emitted when a user creates a password.
  """
  @derive Jason.Encoder
  defstruct [:user_uuid, :hashed_password, :timestamp]
end

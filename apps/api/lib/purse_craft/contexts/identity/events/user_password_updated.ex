defmodule PurseCraft.Identity.Events.UserPasswordUpdated do
  @moduledoc """
  Event emitted when a user's password is updated.
  """
  @derive Jason.Encoder
  defstruct [:user_uuid, :timestamp]
end

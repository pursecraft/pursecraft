defmodule PurseCraft.Identity.Events.UserEmailConfirmed do
  @moduledoc """
  Event emitted when a user's email is confirmed.
  """
  @derive Jason.Encoder
  defstruct [:user_uuid, :email, :timestamp]
end

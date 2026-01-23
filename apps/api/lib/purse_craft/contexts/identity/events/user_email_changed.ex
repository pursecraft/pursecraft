defmodule PurseCraft.Identity.Events.UserEmailChanged do
  @moduledoc """
  Event emitted when a user's email is changed.
  """
  @derive Jason.Encoder
  defstruct [:user_uuid, :old_email, :new_email, :timestamp]
end

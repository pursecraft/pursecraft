defmodule PurseCraft.Identity.Events.UserEmailChangeRequested do
  @moduledoc """
  Event emitted when an email change is requested.
  """
  @derive Jason.Encoder
  defstruct [:user_uuid, :current_email, :new_email, :timestamp]
end

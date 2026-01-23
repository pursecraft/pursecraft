defmodule PurseCraft.Identity.Commands.RequestEmailChange do
  @moduledoc """
  Command to request an email change.
  """
  defstruct [:user_uuid, :new_email]
end

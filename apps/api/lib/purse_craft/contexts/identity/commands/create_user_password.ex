defmodule PurseCraft.Identity.Commands.CreateUserPassword do
  @moduledoc """
  Command to create a password for a user.
  """
  defstruct [:user_uuid, :password, :password_confirmation]
end

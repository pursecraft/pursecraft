defmodule PurseCraft.Identity.Commands.UpdateUserPassword do
  @moduledoc """
  Command to update a user's password.
  """
  defstruct [:user_uuid, :current_password, :new_password, :password_confirmation]
end

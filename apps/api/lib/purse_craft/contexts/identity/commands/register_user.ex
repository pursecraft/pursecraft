defmodule PurseCraft.Identity.Commands.RegisterUser do
  @moduledoc """
  Command to register a new user.
  """
  defstruct [:user_uuid, :email, :password]
end

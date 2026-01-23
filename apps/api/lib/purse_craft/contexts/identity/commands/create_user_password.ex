defmodule PurseCraft.Identity.Commands.CreateUserPassword do
  @moduledoc false
  defstruct [:user_uuid, :password, :password_confirmation]
end

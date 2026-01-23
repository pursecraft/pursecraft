defmodule PurseCraft.Identity.Commands.UpdateUserPassword do
  @moduledoc false
  defstruct [:user_uuid, :current_password, :new_password, :password_confirmation]
end

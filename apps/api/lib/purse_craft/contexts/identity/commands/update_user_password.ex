defmodule PurseCraft.Identity.Commands.UpdateUserPassword do
  @moduledoc false
  @derive {Jason.Encoder, only: [:user_uuid]}
  defstruct [:user_uuid, :current_password, :new_password, :password_confirmation]
end

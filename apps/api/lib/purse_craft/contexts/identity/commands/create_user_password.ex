defmodule PurseCraft.Identity.Commands.CreateUserPassword do
  @moduledoc false
  @derive {Jason.Encoder, only: [:user_uuid]}
  defstruct [:user_uuid, :password, :password_confirmation]
end

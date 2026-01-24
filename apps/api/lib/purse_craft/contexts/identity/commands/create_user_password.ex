defmodule PurseCraft.Identity.Commands.CreateUserPassword do
  @moduledoc false
  @derive {Inspect, only: [:user_uuid]}
  defstruct [:user_uuid, :password, :password_confirmation]
end

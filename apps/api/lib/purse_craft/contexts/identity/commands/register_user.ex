defmodule PurseCraft.Identity.Commands.RegisterUser do
  @moduledoc false
  @derive {Inspect, only: [:user_uuid, :email]}
  defstruct [:user_uuid, :email, :password]
end

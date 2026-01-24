defmodule PurseCraft.Identity.Commands.RegisterUser do
  @moduledoc false
  @derive {Jason.Encoder, only: [:user_uuid, :email]}
  defstruct [:user_uuid, :email, :password]
end

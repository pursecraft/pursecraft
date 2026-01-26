defmodule PurseCraft.Identity.Commands.RequestMagicLink do
  @moduledoc false
  defstruct [:email, :user_uuid, :metadata]
end

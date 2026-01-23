defmodule PurseCraft.Identity.Commands.RequestMagicLink do
  @moduledoc """
  Command to request a magic link for passwordless authentication.
  """
  defstruct [:email, :metadata]
end

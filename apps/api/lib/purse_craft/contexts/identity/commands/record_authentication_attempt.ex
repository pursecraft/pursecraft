defmodule PurseCraft.Identity.Commands.RecordAuthenticationAttempt do
  @moduledoc """
  Command to record an authentication attempt (audit log).
  """
  defstruct [:user_uuid, :success, :metadata]
end

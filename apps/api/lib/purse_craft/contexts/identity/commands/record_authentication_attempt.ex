defmodule PurseCraft.Identity.Commands.RecordAuthenticationAttempt do
  @moduledoc false
  defstruct [:user_uuid, :success, :metadata]
end

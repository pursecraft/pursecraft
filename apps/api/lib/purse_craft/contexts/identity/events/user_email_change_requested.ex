defmodule PurseCraft.Identity.Events.UserEmailChangeRequested do
  @moduledoc false
  defstruct [:user_uuid, :current_email, :new_email, :timestamp]
end

defmodule PurseCraft.Identity.Events.UserEmailChanged do
  @moduledoc false
  defstruct [:user_uuid, :old_email, :new_email, :timestamp]
end

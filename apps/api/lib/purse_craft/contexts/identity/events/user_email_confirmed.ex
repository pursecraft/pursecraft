defmodule PurseCraft.Identity.Events.UserEmailConfirmed do
  @moduledoc false
  defstruct [:user_uuid, :email, :timestamp]
end

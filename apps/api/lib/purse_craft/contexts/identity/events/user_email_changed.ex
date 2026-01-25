defmodule PurseCraft.Identity.Events.UserEmailChanged do
  @moduledoc false
  @derive Jason.Encoder
  defstruct [:user_uuid, :old_email, :new_email]
end

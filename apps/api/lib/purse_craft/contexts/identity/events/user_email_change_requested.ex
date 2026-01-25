defmodule PurseCraft.Identity.Events.UserEmailChangeRequested do
  @moduledoc false
  @derive Jason.Encoder
  defstruct [:user_uuid, :current_email, :new_email]
end

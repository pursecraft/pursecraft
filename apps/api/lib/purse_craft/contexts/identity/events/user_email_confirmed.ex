defmodule PurseCraft.Identity.Events.UserEmailConfirmed do
  @moduledoc false
  @derive Jason.Encoder
  defstruct [:user_uuid, :email, :confirmed_at]
end

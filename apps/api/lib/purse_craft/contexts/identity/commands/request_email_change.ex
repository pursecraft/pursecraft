defmodule PurseCraft.Identity.Commands.RequestEmailChange do
  @moduledoc false
  defstruct [:user_uuid, :new_email]
end

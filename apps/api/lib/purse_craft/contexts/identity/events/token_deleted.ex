defmodule PurseCraft.Identity.Events.TokenDeleted do
  @moduledoc false
  @derive Jason.Encoder
  defstruct [:token, :timestamp]
end

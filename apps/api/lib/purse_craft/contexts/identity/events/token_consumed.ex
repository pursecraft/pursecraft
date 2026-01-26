defmodule PurseCraft.Identity.Events.TokenConsumed do
  @moduledoc false
  @derive Jason.Encoder
  defstruct [:token, :consumed_at]
end

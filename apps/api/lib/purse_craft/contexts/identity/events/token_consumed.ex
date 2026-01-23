defmodule PurseCraft.Identity.Events.TokenConsumed do
  @moduledoc """
  Event emitted when a one-time token is consumed.
  """
  @derive Jason.Encoder
  defstruct [:token, :consumed_at, :timestamp]
end

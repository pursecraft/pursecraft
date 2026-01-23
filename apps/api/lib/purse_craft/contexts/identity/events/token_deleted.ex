defmodule PurseCraft.Identity.Events.TokenDeleted do
  @moduledoc """
  Event emitted when a token is deleted.
  """
  @derive Jason.Encoder
  defstruct [:token, :timestamp]
end

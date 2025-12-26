defmodule PurseCraft.EventStore do
  @moduledoc false

  use EventStore, otp_app: :purse_craft

  def init(config) do
    {:ok, config}
  end
end

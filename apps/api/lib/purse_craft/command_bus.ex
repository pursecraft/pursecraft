defmodule PurseCraft.CommandBus do
  @moduledoc false

  use Commanded.Application, otp_app: :purse_craft

  @impl Commanded.Application
  def init(config) do
    {:ok, config}
  end
end

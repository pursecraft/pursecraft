defmodule PurseCraft.Cache do
  @moduledoc false

  use Nebulex.Cache,
    otp_app: :purse_craft,
    adapter: Nebulex.Adapters.Local
end

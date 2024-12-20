defmodule PurseCraft.Repo do
  use Ecto.Repo,
    otp_app: :purse_craft,
    adapter: Ecto.Adapters.Postgres
end

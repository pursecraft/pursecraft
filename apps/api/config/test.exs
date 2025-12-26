import Config

# Print only warnings and errors during test
config :logger, level: :warning

# Initialize plugs at runtime for faster test compilation
config :phoenix, :plug_init_mode, :runtime

# Sort query params output of verified routes for robust url comparisons
config :phoenix,
  sort_verified_routes_query_params: true

# Enable helpful, but potentially expensive runtime checks
config :phoenix_live_view,
  enable_expensive_runtime_checks: true

config :purse_craft, PurseCraft.EventStore,
  serializer: Commanded.Serialization.JsonSerializer,
  username: "postgres",
  password: "postgres",
  hostname: "localhost",
  database: "purse_craft_event_store_test#{System.get_env("MIX_TEST_PARTITION")}",
  queue_interval: 1_000,
  queue_target: 50

# In test we don't send emails
config :purse_craft, PurseCraft.Mailer, adapter: Swoosh.Adapters.Test

# Configure your database
#
# The MIX_TEST_PARTITION environment variable can be used
# to provide built-in test partitioning in CI environment.
# Run `mix help test` for more information.
config :purse_craft, PurseCraft.Repo,
  username: "postgres",
  password: "postgres",
  hostname: "localhost",
  database: "purse_craft_test#{System.get_env("MIX_TEST_PARTITION")}",
  pool: Ecto.Adapters.SQL.Sandbox,
  pool_size: System.schedulers_online() * 2

# We don't run a server during test. If one is required,
# you can enable the server option below.
config :purse_craft, PurseCraftWeb.Endpoint,
  http: [ip: {127, 0, 0, 1}, port: 4002],
  secret_key_base: "zfqkUTz3IQodWBwdsYo4uoEsVDsibmusVISSKGD5foT3uXYfMWPkK1gWAxi8Q6T6",
  server: false

# Disable swoosh api client as it is only required for production adapters
config :swoosh, :api_client, false

# This file is responsible for configuring your application
# and its dependencies with the aid of the Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.

# General application configuration
import Config

# Configure esbuild (the version is required)
config :esbuild,
  version: "0.17.11",
  purse_craft: [
    args:
      ~w(js/app.js --bundle --target=es2022 --outdir=../priv/static/assets/js --external:/fonts/* --external:/images/*),
    cd: Path.expand("../assets", __DIR__),
    env: %{"NODE_PATH" => Path.expand("../deps", __DIR__)}
  ]

# Configures Elixir's Logger
config :logger, :default_formatter,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

# Use Jason for JSON parsing in Phoenix
config :phoenix, :json_library, Jason

# Configures the mailer
#
# By default it uses the "Local" adapter which stores the emails
# locally. You can see the emails in your browser, at "/dev/mailbox".
#
# For production it's recommended to configure a different adapter
# at the `config/runtime.exs`.
config :purse_craft, PurseCraft.Mailer, adapter: Swoosh.Adapters.Local

# Configures the endpoint
config :purse_craft, PurseCraftWeb.Endpoint,
  url: [host: "localhost"],
  adapter: Bandit.PhoenixAdapter,
  render_errors: [
    formats: [html: PurseCraftWeb.ErrorHTML, json: PurseCraftWeb.ErrorJSON],
    layout: false
  ],
  pubsub_server: PurseCraft.PubSub,
  live_view: [signing_salt: "VWLiUyYa"]

config :purse_craft, :scopes,
  user: [
    default: true,
    module: PurseCraft.Identity.Schemas.Scope,
    assign_key: :current_scope,
    access_path: [:user, :id],
    schema_key: :user_id,
    schema_type: :id,
    schema_table: :users,
    test_data_fixture: PurseCraft.TestHelpers.IdentityHelper,
    test_login_helper: :register_and_log_in_user
  ],
  book: [
    module: PurseCraft.Identity.Schemas.Scope,
    assign_key: :current_scope,
    access_path: [:book, :id],
    route_prefix: "/books/:id",
    schema_key: :book_id,
    schema_type: :id,
    schema_table: :books,
    test_data_fixture: PurseCraft.TestHelpers.BudgetingHelper,
    test_login_helper: :register_and_log_in_user_with_book
  ]

config :purse_craft,
  ecto_repos: [PurseCraft.Repo],
  generators: [timestamp_type: :utc_datetime]

# Configure tailwind (the version is required)
config :tailwind,
  version: "4.0.9",
  purse_craft: [
    args: ~w(
      --input=assets/css/app.css
      --output=priv/static/assets/css/app.css
    ),
    cd: Path.expand("..", __DIR__)
  ]

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{config_env()}.exs"

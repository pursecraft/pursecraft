defmodule PurseCraft.MixProject do
  use Mix.Project

  def project do
    [
      app: :purse_craft,
      version: "0.1.0",
      elixir: "1.18.0",
      elixirc_paths: elixirc_paths(Mix.env()),
      start_permanent: Mix.env() == :prod,
      aliases: aliases(),
      deps: deps()
    ]
  end

  # Configuration for the OTP application.
  #
  # Type `mix help compile.app` for more information.
  def application do
    [
      mod: {PurseCraft.Application, []},
      extra_applications: [:logger, :runtime_tools]
    ]
  end

  # Specifies which paths to compile per environment.
  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  # Specifies your project dependencies.
  #
  # Type `mix help deps` for examples and options.
  defp deps do
    [
      {:bandit, "1.6.1"},
      {:dns_cluster, "0.1.3"},
      {:ecto_sql, "3.12.1"},
      {:esbuild, "0.8.2", runtime: Mix.env() == :dev},
      {:finch, "0.19.0"},
      {:floki, "0.37.0", only: :test},
      {:gettext, "0.26.2"},
      {:heroicons,
       github: "tailwindlabs/heroicons",
       tag: "v2.1.1",
       sparse: "optimized",
       app: false,
       compile: false,
       depth: 1},
      {:jason, "1.4.4"},
      {:phoenix, "1.7.18"},
      {:phoenix_ecto, "4.6.3"},
      {:phoenix_html, "4.1.1"},
      {:phoenix_live_reload, "1.5.3", only: :dev},
      {:phoenix_live_view, "1.0.1"},
      {:postgrex, "0.19.3"},
      {:phoenix_live_dashboard, "0.8.5"},
      {:swoosh, "1.17.5"},
      {:tailwind, "0.2.4", runtime: Mix.env() == :dev},
      {:telemetry_metrics, "1.0.0"},
      {:telemetry_poller, "1.1.0"}
    ]
  end

  # Aliases are shortcuts or tasks specific to the current project.
  # For example, to install project dependencies and perform other setup tasks, run:
  #
  #     $ mix setup
  #
  # See the documentation for `Mix` for more info on aliases.
  defp aliases do
    [
      setup: ["deps.get", "ecto.setup", "assets.setup", "assets.build"],
      "ecto.setup": ["ecto.create", "ecto.migrate", "run priv/repo/seeds.exs"],
      "ecto.reset": ["ecto.drop", "ecto.setup"],
      test: ["ecto.create --quiet", "ecto.migrate --quiet", "test"],
      "assets.setup": ["tailwind.install --if-missing", "esbuild.install --if-missing"],
      "assets.build": ["tailwind purse_craft", "esbuild purse_craft"],
      "assets.deploy": [
        "tailwind purse_craft --minify",
        "esbuild purse_craft --minify",
        "phx.digest"
      ],
      lint: ["format"],
      "lint.ci": ["format --check-formatted"]
    ]
  end
end

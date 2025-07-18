defmodule PurseCraft.MixProject do
  use Mix.Project

  def project do
    [
      app: :purse_craft,
      version: "0.0.0",
      elixir: "1.18.3",
      elixirc_paths: elixirc_paths(Mix.env()),
      start_permanent: Mix.env() == :prod,
      aliases: aliases(),
      deps: deps(),
      listeners: [Phoenix.CodeReloader],
      test_coverage: [tool: ExCoveralls],
      preferred_cli_env: [
        coveralls: :test,
        "coveralls.detail": :test,
        "coveralls.post": :test,
        "coveralls.html": :test,
        "coveralls.cobertura": :test
      ],
      dialyzer: [
        plt_add_apps: [
          :ex_unit
        ],
        plt_file: {:no_warn, "priv/plts/project.plt"},
        list_unused_filter: true
      ]
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
      {:bandit, "1.6.11"},
      {:bcrypt_elixir, "3.2.1"},
      {:cloak, "1.1.4"},
      {:cloak_ecto, "1.3.0"},
      {:credo, "1.7.11", only: [:dev, :test], runtime: false},
      {:dialyxir, "1.4.5", only: [:dev, :test], runtime: false},
      {:dns_cluster, "0.1.3"},
      {:ecto_sql, "3.12.1"},
      {:esbuild, "0.9.0", runtime: Mix.env() == :dev},
      {:ex_machina, "2.8.0", only: :test},
      {:excoveralls, "0.18.5", only: :test},
      {:faker, "0.18.0", only: :test},
      {:floki, "0.37.1", only: :test},
      {:gettext, "0.26.2"},
      {:mimic, "1.11.2", only: :test},
      {:heroicons,
       github: "tailwindlabs/heroicons", tag: "v2.1.1", sparse: "optimized", app: false, compile: false, depth: 1},
      {:jason, "1.4.4"},
      {:let_me, "1.2.5"},
      {:nebulex, "2.6.4"},
      {:oban, "2.19.4"},
      {:phoenix, "1.8.0-rc.0", override: true},
      {:phoenix_ecto, "4.6.3"},
      {:phoenix_html, "4.2.1"},
      {:phoenix_live_dashboard, "0.8.6"},
      {:phoenix_live_reload, "1.5.3", only: :dev},
      {:phoenix_live_view, "1.0.9"},
      {:postgrex, "0.20.0"},
      {:req, "0.5.10"},
      {:styler, "1.4.1", only: [:dev, :test], runtime: false},
      {:swoosh, "1.18.4"},
      {:tailwind, "0.3.1", runtime: Mix.env() == :dev},
      {:telemetry_metrics, "1.1.0"},
      {:telemetry_poller, "1.2.0"},
      {:tidewave, "0.2.0", only: :dev}
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
      "ecto.setup.dev": ["ecto.setup", "run priv/repo/dummy_data.exs"],
      "ecto.reset": ["ecto.drop", "ecto.setup"],
      "ecto.reset.dev": ["ecto.drop", "ecto.setup.dev"],
      test: ["ecto.create --quiet", "ecto.migrate --quiet", "test"],
      "assets.setup": ["tailwind.install --if-missing", "esbuild.install --if-missing"],
      "assets.build": ["tailwind purse_craft", "esbuild purse_craft"],
      "assets.deploy": [
        "tailwind purse_craft --minify",
        "esbuild purse_craft --minify",
        "phx.digest"
      ],
      lint: ["format", "credo"],
      "lint.ci": ["format --check-formatted", "credo"]
    ]
  end
end

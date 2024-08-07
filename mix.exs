defmodule PurseCraft.MixProject do
  use Mix.Project

  def project do
    [
      app: :purse_craft,
      version: "0.0.0",
      elixir: "1.17.2",
      elixirc_paths: elixirc_paths(Mix.env()),
      start_permanent: Mix.env() == :prod,
      aliases: aliases(),
      deps: deps(),
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
      {:bandit, "1.5.7"},
      {:credo, "1.7.7", only: [:dev, :test], runtime: false},
      {:dialyxir, "1.4.3", only: [:dev, :test], runtime: false},
      {:dns_cluster, "0.1.3"},
      {:ecto_sql, "3.11.3"},
      {:esbuild, "0.8.1", runtime: Mix.env() == :dev},
      {:ex_machina, "2.8.0", only: :test},
      {:excoveralls, "0.18.2", only: :test},
      {:faker, "0.18.0", only: :test},
      {:finch, "0.18.0"},
      {:floki, "0.36.2", only: :test},
      {:gettext, "0.25.0"},
      {:heroicons,
       github: "tailwindlabs/heroicons",
       tag: "v2.1.1",
       sparse: "optimized",
       app: false,
       compile: false,
       depth: 1},
      {:jason, "1.4.4"},
      {:phoenix, "1.7.14"},
      {:phoenix_ecto, "4.6.2"},
      {:phoenix_html, "4.1.1"},
      {:phoenix_live_dashboard, "0.8.4"},
      {:phoenix_live_reload, "1.5.3", only: :dev},
      # TODO bump on release to {:phoenix_live_view, "~> 1.0.0"},
      {:phoenix_live_view, "1.0.0-rc.6", override: true},
      {:postgrex, "0.19.0"},
      {:swoosh, "1.16.10"},
      {:tailwind, "0.2.3", runtime: Mix.env() == :dev},
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
      "assets.build": ["tailwind purse_craft", "esbuild purse_craft"],
      "assets.deploy": [
        "tailwind purse_craft --minify",
        "esbuild purse_craft --minify",
        "phx.digest"
      ],
      "assets.setup": ["tailwind.install --if-missing", "esbuild.install --if-missing"],
      "ecto.reset": ["ecto.drop", "ecto.setup"],
      "ecto.setup": ["ecto.create", "ecto.migrate", "run priv/repo/seeds.exs"],
      lint: ["format", "credo"],
      "lint.ci": ["format --check-formatted", "credo"],
      setup: ["deps.get", "ecto.setup", "assets.setup", "assets.build"],
      test: ["ecto.create --quiet", "ecto.migrate --quiet", "test"]
    ]
  end
end

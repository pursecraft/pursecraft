defmodule PurseCraft.MixProject do
  use Mix.Project

  def project do
    [
      app: :purse_craft,
      version: "0.0.0",
      elixir: "1.18.4",
      elixirc_paths: elixirc_paths(Mix.env()),
      start_permanent: Mix.env() == :prod,
      aliases: aliases(),
      deps: deps(),
      compilers: [:phoenix_live_view] ++ Mix.compilers(),
      listeners: [Phoenix.CodeReloader]
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

  def cli do
    [
      preferred_envs: [precommit: :test]
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
      {:bandit, "1.9.0"},
      {:dns_cluster, "0.2.0"},
      {:ecto_sql, "3.13.3"},
      {:esbuild, "0.10.0", runtime: Mix.env() == :dev},
      {:gettext, "1.0.2"},
      {:heroicons,
       github: "tailwindlabs/heroicons",
       tag: "v2.2.0",
       sparse: "optimized",
       app: false,
       compile: false,
       depth: 1},
      {:jason, "1.4.4"},
      {:lazy_html, "0.1.8", only: :test},
      {:phoenix, "1.8.3"},
      {:phoenix_ecto, "4.7.0"},
      {:phoenix_html, "4.3.0"},
      {:phoenix_live_dashboard, "0.8.7"},
      {:phoenix_live_reload, "1.6.2", only: :dev},
      {:phoenix_live_view, "1.1.19"},
      {:postgrex, "0.21.1"},
      {:req, "0.5.16"},
      {:swoosh, "1.19.9"},
      {:tailwind, "0.4.1", runtime: Mix.env() == :dev},
      {:telemetry_metrics, "1.1.0"},
      {:telemetry_poller, "1.3.0"}
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
      "assets.build": ["compile", "tailwind purse_craft", "esbuild purse_craft"],
      "assets.deploy": [
        "tailwind purse_craft --minify",
        "esbuild purse_craft --minify",
        "phx.digest"
      ],
      "assets.setup": ["tailwind.install --if-missing", "esbuild.install --if-missing"],
      "ecto.reset": ["ecto.drop", "ecto.setup"],
      "ecto.setup": ["ecto.create", "ecto.migrate", "run priv/repo/seeds.exs"],
      precommit: ["compile --warnings-as-errors", "deps.unlock --unused", "format", "test"],
      setup: ["deps.get", "ecto.setup", "assets.setup", "assets.build"],
      test: ["ecto.create --quiet", "ecto.migrate --quiet", "test"]
    ]
  end
end

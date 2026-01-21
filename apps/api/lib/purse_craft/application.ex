defmodule PurseCraft.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl Application
  def start(_type, _args) do
    children = [
      PurseCraftWeb.Telemetry,
      PurseCraft.EventStore,
      PurseCraft.Repo,
      {DNSCluster, query: Application.get_env(:purse_craft, :dns_cluster_query) || :ignore},
      {Phoenix.PubSub, name: PurseCraft.PubSub},
      # Start a worker by calling: PurseCraft.Worker.start_link(arg)
      # {PurseCraft.Worker, arg},
      # Start to serve requests, typically the last entry
      PurseCraftWeb.Endpoint
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: PurseCraft.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl Application
  def config_change(changed, _new, removed) do
    PurseCraftWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end

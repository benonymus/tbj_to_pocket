defmodule TbjToPocket.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      {CubDB, name: :cubdb, data_dir: "./data", auto_compact: true},
      TbjToPocketWeb.Telemetry,
      {DNSCluster, query: Application.get_env(:tbj_to_pocket, :dns_cluster_query) || :ignore},
      {Phoenix.PubSub, name: TbjToPocket.PubSub},
      # Start a worker by calling: TbjToPocket.Worker.start_link(arg)
      # {TbjToPocket.Worker, arg},
      # Start to serve requests, typically the last entry
      TbjToPocketWeb.Endpoint
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: TbjToPocket.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    TbjToPocketWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end

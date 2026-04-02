defmodule TbjToPocket.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    redis_opts = [name: :redix]

    redis_opts =
      if Application.fetch_env!(:tbj_to_pocket, :redis_ssl) do
        Keyword.merge(redis_opts,
          ssl: true,
          socket_opts: [
            customize_hostname_check: [
              match_fun: :public_key.pkix_verify_hostname_match_fun(:https)
            ]
          ]
        )
      else
        redis_opts
      end

    children = [
      {Redix, {Application.fetch_env!(:tbj_to_pocket, :redis_url), redis_opts}},
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

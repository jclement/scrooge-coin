defmodule ScroogeCoin.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      ScroogeCoinWeb.Telemetry,
      {DNSCluster, query: Application.get_env(:scrooge_coin, :dns_cluster_query) || :ignore},
      {Phoenix.PubSub, name: ScroogeCoin.PubSub},
      # Start the Finch HTTP client for sending emails
      {Finch, name: ScroogeCoin.Finch},
      # Start a worker by calling: ScroogeCoin.Worker.start_link(arg)
      # {ScroogeCoin.Worker, arg},
      ScroogeCoin.Server,
      # Start to serve requests, typically the last entry
      ScroogeCoinWeb.Endpoint
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: ScroogeCoin.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    ScroogeCoinWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end

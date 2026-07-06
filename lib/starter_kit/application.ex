defmodule StarterKit.Application do
  # See https://elixir.hexdocs.pm/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      StarterKitWeb.Telemetry,
      StarterKit.Repo,
      {DNSCluster, query: Application.get_env(:starter_kit, :dns_cluster_query) || :ignore},
      {Phoenix.PubSub, name: StarterKit.PubSub},
      # Start a worker by calling: StarterKit.Worker.start_link(arg)
      # {StarterKit.Worker, arg},
      # Start to serve requests, typically the last entry
      StarterKitWeb.Endpoint,
      {AshAuthentication.Supervisor, [otp_app: :starter_kit]}
    ]

    # See https://elixir.hexdocs.pm/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: StarterKit.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    StarterKitWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end

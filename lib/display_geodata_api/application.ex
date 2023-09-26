defmodule DisplayGeodataApi.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      # Start the Telemetry supervisor
      DisplayGeodataApiWeb.Telemetry,
      # Start the Ecto repository
      DisplayGeodataApi.Repo,
      # Start the PubSub system
      {Phoenix.PubSub, name: DisplayGeodataApi.PubSub},
      # Start Finch
      {Finch, name: DisplayGeodataApi.Finch},
      # Start the Endpoint (http/https)
      DisplayGeodataApiWeb.Endpoint
      # Start a worker by calling: DisplayGeodataApi.Worker.start_link(arg)
      # {DisplayGeodataApi.Worker, arg}
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: DisplayGeodataApi.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    DisplayGeodataApiWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end

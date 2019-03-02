defmodule ElasticConsumer.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  def start(_type, _args) do
    # List all child processes to be supervised
    children = [
      # Starts a worker by calling: ElasticConsumer.Worker.start_link(arg)
      # {ElasticConsumer.Worker, arg}
      %{
        id: ElasticConsumer,
        start: {ElasticConsumer, :start_link, []}
      }
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: ElasticConsumer.Supervisor]
    Supervisor.start_link(children, opts)
  end
end

defmodule SquiggleRelay.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      Supervisor.child_spec({SquiggleRelay.Realtime, channel: "events"},
        id: {SquiggleRelay.Realtime, "events"}
      ),
      Supervisor.child_spec({SquiggleRelay.Realtime, channel: "test"},
        id: {SquiggleRelay.Realtime, "test"}
      ),
      {Phoenix.PubSub, name: SquiggleRelay.PubSub},
      {Bandit, plug: SquiggleRelay.Router, scheme: :http, port: 4000}
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: SquiggleRelay.Supervisor]
    Supervisor.start_link(children, opts)
  end
end

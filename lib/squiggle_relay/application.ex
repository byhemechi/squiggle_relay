defmodule SquiggleRelay.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      {Phoenix.PubSub, name: SquiggleRelay.PubSub},
      {Bandit, plug: SquiggleRelay.Router, scheme: :http, port: 4000}
      | for channel <- Application.get_env(:squiggle_relay, :channels) do
          Supervisor.child_spec({SquiggleRelay.Realtime, channel: channel},
            id: {SquiggleRelay.Realtime, channel}
          )
        end
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: SquiggleRelay.Supervisor]
    Supervisor.start_link(children, opts)
  end
end

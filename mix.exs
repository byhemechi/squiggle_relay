defmodule SquiggleRelay.MixProject do
  use Mix.Project

  def project do
    [
      app: :squiggle_relay,
      version: "0.1.0",
      elixir: "~> 1.18",
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger],
      mod: {SquiggleRelay.Application, []}
    ]
  end

  defp deps do
    [
      {:req, "~> 0.5"},
      {:server_sent_events, "~> 0.2"},
      {:plug, "~> 1.18"},
      {:bandit, "~> 1.0"},
      {:websock, "~> 0.5"},
      {:uuid, "~> 1.1"},
      {:websock_adapter, "~> 0.5"},
      {:phoenix_pubsub, "~> 2.1"},
      {:esbuild, "~> 0.10"},
      {:mdex, "~> 0.8"},
      {:phoenix_html, "~> 4.2"},
      {:floki, "~> 0.38"}
    ]
  end
end

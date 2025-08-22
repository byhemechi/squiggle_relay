import Config

config :squiggle_relay,
  user_agent: "squiggle_relay #{config_env()} - byhemechi on twitter or discord"

global_args = ~w(--bundle --target=safari16 --format=esm)

config :esbuild,
  version: "0.25.0",
  library: [
    args: ~w(./squiggle_realtime --outdir=../../priv/static/lib/) ++ global_args,
    cd: Path.expand("../assets/lib", __DIR__),
    env: %{"NODE_PATH" => Path.expand("../deps", __DIR__)}
  ],
  client: [
    args:
      [
        "../assets/components/*/index.{t,j}s"
        |> Path.expand(__DIR__)
        |> Path.relative_to("../assets")
        |> Path.wildcard()
        |> Enum.map(&Path.dirname/1),
        ~w(
        app.css
        home/home.css
        --external:client_data
        --splitting
        --alias:squiggle_realtime=./lib/squiggle_realtime
        --loader:.html=copy
        --metafile=../priv/static/bundle.json
        --outdir=../priv/static/assets/
        ),
        global_args,
        if(config_env() == :prod, do: ["--entry-names=[dir]/[name]-[hash]"], else: [])
      ]
      |> List.flatten(),
    cd: Path.expand("../assets", __DIR__),
    env: %{"NODE_PATH" => Path.expand("../deps", __DIR__)}
  ]

import_config "#{config_env()}.exs"

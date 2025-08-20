import Config
global_args = ~w(--splitting --bundle --target=es2022 --format=esm )

config :esbuild,
  version: "0.25.0",
  library: [
    args: ~w(squiggle_realtime.ts --outdir=../../priv/static/lib/) ++ global_args,
    cd: Path.expand("../assets/lib", __DIR__),
    env: %{"NODE_PATH" => Path.expand("../deps", __DIR__)}
  ],
  client: [
    args:
      ~w(demo.ts home.css --external:squiggle_realtime --splitting --outdir=../../priv/static/assets/) ++
        global_args,
    cd: Path.expand("../assets/home", __DIR__),
    env: %{"NODE_PATH" => Path.expand("../deps", __DIR__)}
  ]

import_config "#{config_env()}.exs"

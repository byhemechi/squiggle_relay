import Config
global_args = ~w(--bundle --target=es2022 --format=esm )

config :esbuild,
  version: "0.25.0",
  library: [
    args: ~w(squiggle_realtime.ts --outdir=../../priv/static/lib/) ++ global_args,
    cd: Path.expand("../assets/lib", __DIR__),
    env: %{"NODE_PATH" => Path.expand("../deps", __DIR__)}
  ],
  client: [
    args:
      [
        ~w(
        home/demo.ts home/home.css
        --external:squiggle_realtime
        --splitting
        --metafile=../lib/squiggle_relay/bundle.json
        --outdir=../priv/static/assets/
        --entry-names=[dir]/[name]-[hash]
        ),
        global_args
      ]
      |> List.flatten(),
    cd: Path.expand("../assets", __DIR__),
    env: %{"NODE_PATH" => Path.expand("../deps", __DIR__)}
  ]

import_config "#{config_env()}.exs"

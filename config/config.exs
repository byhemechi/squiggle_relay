import Config

config :esbuild,
  version: "0.25.0",
  client: [
    args:
      ~w(lib/squiggle_realtime.ts js/demo.ts --external:squiggle_realtime --bundle --target=es2022 --format=esm --outdir=../priv/static/),
    cd: Path.expand("../assets", __DIR__),
    env: %{"NODE_PATH" => Path.expand("../deps", __DIR__)}
  ]

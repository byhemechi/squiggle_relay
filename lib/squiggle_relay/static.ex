defmodule SquiggleRelay.Static do
  use Plug.Builder

  plug(Plug.Static,
    at: "/",
    from: {:squiggle_relay, "priv/static"},
    only: ~w(lib assets)
  )

  plug(:not_found)

  def not_found(conn, _) do
    send_resp(conn, 404, "not found")
  end
end

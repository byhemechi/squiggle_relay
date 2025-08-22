defmodule SquiggleRelay.Static do
  use Plug.Builder

  plug(Plug.Static,
    at: "/",
    from: {:squiggle_relay, "priv/static"},
    only: ~w(lib assets)
  )

  plug(:not_found)

  def not_found(conn, _ \\ []) do
    conn
    |> put_resp_content_type("text/html")
    |> send_resp(
      404,
      SquiggleRelay.Templates."page.html"(
        title: "Page not found",
        body: "<h1>404 - Page not found</h1>"
      )
    )
  end
end

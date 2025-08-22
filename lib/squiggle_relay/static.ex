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
        body: """
        <center>
          <h1>404 - Page not found</h1>
          <p>Looks like you've either followed a dead link or typed in a URL wrong.</p>
          <p>You could <a href="/">go back to the homepage</a></p>
        </center>
        """
      )
    )
  end
end

defmodule SquiggleRelay.Router do
  require SquiggleRelay.Templates
  use Plug.Router

  plug(Plug.Logger)
  plug(:match)
  plug(:dispatch)

  get "/lib/client.js" do
    live_channels =
      for {{SquiggleRelay.Realtime, channel}, _pid, :worker, [SquiggleRelay.Realtime | _]} <-
            Supervisor.which_children(SquiggleRelay.Supervisor) do
        channel
      end
      |> Enum.uniq()

    conn
    |> put_resp_content_type("application/javascript")
    |> send_resp(200, SquiggleRelay.Templates."client.js"(channels: live_channels))
  end

  @readme Path.join(__DIR__, "../../README.md")
          |> File.read!()
          |> MDEx.to_html!(syntax_highlight: [formatter: :html_linked])

  get "/" do
    bundle =
      SquiggleRelay.Bundle.resource("home/home.css")

    conn
    |> put_resp_content_type("text/html")
    |> send_resp(
      200,
      SquiggleRelay.Templates."home.html"([title: "Squiggle Event Relay", body: @readme], bundle)
    )
  end

  get "/healthz" do
    send_resp(conn, 200, "OK")
  end

  defp find_realtime_server(channel) do
    Supervisor.which_children(SquiggleRelay.Supervisor)
    |> Enum.find(fn
      {{SquiggleRelay.Realtime, ^channel}, _pid, :worker, [SquiggleRelay.Realtime | _]} ->
        true

      _ ->
        false
    end)
  end

  get "/websocket/:channel" do
    with %Plug.Conn{req_headers: headers} <- conn,
         %{"upgrade" => "websocket"} <- Enum.into(headers, %{}),
         {_, _, _, _} <- find_realtime_server(channel) do
      conn
      |> WebSockAdapter.upgrade(SquiggleRelay.WebSocketEndpoint, %{channel: channel}, [])
      |> halt()
    else
      _ ->
        SquiggleRelay.Static.not_found(conn)
    end
  end

  match(_, to: SquiggleRelay.Static)
end

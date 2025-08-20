defmodule SquiggleRelay.Router do
  use Plug.Router

  plug(Plug.Logger)
  plug(:match)
  plug(:dispatch)

  defp send_not_found(conn) do
    send_resp(conn, 404, "not found")
  end

  get "/" do
    live_channels =
      for {{SquiggleRelay.Realtime, channel}, _pid, :worker, [SquiggleRelay.Realtime | _]} <-
            Supervisor.which_children(SquiggleRelay.Supervisor) do
        channel
      end

    send_resp(conn, 200, """
    // JavaScript example code.
    const allowedChannels = new Set(#{JSON.encode_to_iodata!(live_channels)})

    const channel = "test" // Returns random data for testing, change this to receive actual data

    if(!allowedChannels.has(channel)) throw new Error("Invalid WebSocket Channel ID")

    const sock = new WebSocket(`/websocket/${encodeURI(channel)}`);
    sock.addEventListener("message", ({ data }) => {
      switch(data) {
        case "pong":
          break;

        case "ping":
          sock.send("pong")
          break;

        default:
          console.log("Received message from WebSocket:", JSON.parse(data));
      }
    })

    // The socket will time out if no data is received for 60 seconds, send a message every 30 seconds to avoid this
    setInterval(() => sock.send("ping"), 30000)
    """)
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
      _ -> send_not_found(conn)
    end
  end

  match _ do
    send_not_found(conn)
  end
end

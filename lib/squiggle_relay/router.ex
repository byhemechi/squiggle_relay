defmodule SquiggleRelay.Router do
  use Plug.Router

  plug(Plug.Logger)
  plug(:match)
  plug(:dispatch)

  defp send_not_found(conn) do
    send_resp(conn, 404, "not found")
  end

  get "/lib/client.js" do
    live_channels =
      for {{SquiggleRelay.Realtime, channel}, pid, :worker, [SquiggleRelay.Realtime | _]} <-
            Supervisor.which_children(SquiggleRelay.Supervisor) do
        {channel, pid}
      end

    conn
    |> put_resp_content_type("application/javascript")
    |> send_resp(200, [
      "export const activeChannels = new Set(",
      JSON.encode_to_iodata!(Enum.map(live_channels, &elem(&1, 0))),
      ");\n\n",
      "const SquiggleChannel = {",
      for {channel, pid} <- live_channels do
        [
          "\n  get ",
          channel
          |> String.replace(~r/[^a-z]+/, "_")
          |> Macro.camelize(),
          """
          () {
          """,
          """
              return import(\"/lib/squiggle_realtime.js\")
                .then(
                  ({ default: SquiggleRealtime }) =>
                    new SquiggleRealtime(\
          """,
          JSON.encode_to_iodata!(channel),
          """
          )
                )
            },\
          """
        ]
      end,
      "\n}\n\nexport default SquiggleChannel;"
    ])
  end

  get "/" do
    priv_dir = :code.priv_dir(:squiggle_relay)
    index_path = Path.join([priv_dir, "static", "index.html"])

    conn
    |> put_resp_content_type("text/html")
    |> send_file(200, index_path)
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

  match(_, to: SquiggleRelay.Static)
end

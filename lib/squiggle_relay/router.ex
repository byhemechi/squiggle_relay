defmodule SquiggleRelay.Router do
  require SquiggleRelay.Templates
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
      for {channel, _pid} <- live_channels do
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

  @readme Path.join(__DIR__, "../../README.md")
          |> File.read!()
          |> MDEx.to_html!(syntax_highlight: [formatter: :html_linked])

  get "/" do
    require SquiggleRelay.Templates

    bundle =
      [
        SquiggleRelay.Bundle.paths("home/home.css"),
        SquiggleRelay.Bundle.paths("home/demo.ts")
      ]
      |> SquiggleRelay.Bundle.merge()
      |> SquiggleRelay.Bundle.render()

    args =
      bundle
      |> Map.put(:title, "Squiggle Event Relay")
      |> Map.put(:body, @readme)

    conn
    |> put_resp_content_type("text/html")
    |> send_resp(200, SquiggleRelay.Templates.home(args))
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

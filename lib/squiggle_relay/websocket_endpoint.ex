defmodule SquiggleRelay.WebSocketEndpoint do
  @behaviour WebSock

  defp reply_json(term) do
    {:text, JSON.encode_to_iodata!(term)}
  end

  def init(%{channel: channel} = init_state) do
    Phoenix.PubSub.subscribe(SquiggleRelay.PubSub, "squiggle_#{channel}")

    send(self(), :connected)

    Process.send_after(self(), :send_keepalive, 30_000)
    {:ok, init_state}
  end

  def handle_in({"ping", [opcode: :text]}, state) do
    {:reply, :ok, {:text, "pong"}, state}
  end

  def handle_in({"pong", [opcode: :text]}, state) do
    {:ok, state}
  end

  def handle_info(:send_keepalive, state) do
    {:push, {:text, "ping"}, state}
  end

  def handle_info(:connected, state) do
    {:push,
     [
       reply_json(%{retry: 2000, timeout: 60_000}),
       reply_json(%SquiggleRelay.Event{
         event: :message,
         data: """
         Welcome to George's Squiggle SSE relay.

         This exists to reduce load on Squiggle's SSE server, which caps out at 40 concurrent subscribers.
         It should handle thousands of concurrent connections without issue.

         Please don't use this if you absolutely need to receive all messages, at this point I can't guarantee uptime.
         """
       })
     ], state}
  end

  def handle_info({:squiggle_event, channel, %SquiggleRelay.Event{} = event}, state)
      when channel == state.channel do
    {:push, reply_json(event), state}
  end

  def terminate(:timeout, state) do
    {:ok, state}
  end

  def terminate(:remote, state) do
    {:ok, state}
  end

  def terminate(_reason, state) do
    {:ok, state}
  end
end

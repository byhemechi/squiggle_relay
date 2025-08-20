defmodule SquiggleRelay.Realtime do
  use GenServer
  require Logger

  @timeout :timer.minutes(1)
  @initial_retry_delay :timer.seconds(1)
  @max_retry_delay :timer.minutes(5)

  defstruct [
    :pid,
    :channel,
    retry_count: 0,
    retry_delay: @initial_retry_delay
  ]

  def init(channel) do
    state =
      start_stream(%__MODULE__{
        pid: self(),
        channel: channel
      })

    {:ok, state}
  end

  defp start_stream(%__MODULE{channel: channel} = state) do
    Task.start_link(fn ->
      Req.get("https://api.squiggle.com.au/sse/#{channel}",
        into: fn {:data, data}, {req, res} ->
          # Reset the connection timer since we received data
          pid = Req.Request.get_private(req, :pid) || state.pid
          old_timer = Req.Request.get_private(req, :timer)
          if old_timer, do: Process.cancel_timer(old_timer)

          new_timer = Process.send_after(pid, :check_connection, @timeout)

          buffer = Req.Request.get_private(req, :sse_buffer, "")
          {events, new_buffer} = ServerSentEvents.parse(buffer <> data)

          req =
            req
            |> Req.Request.put_private(:timer, new_timer)
            |> Req.Request.put_private(:pid, pid)
            |> Req.Request.put_private(:sse_buffer, new_buffer)

          if events != [] do
            for event <- events do
              send(pid, {:squiggle_event, event})
            end
          end

          {:cont, {req, res}}
        end,
        headers: %{
          "user-agent" => "George's Squiggle API relay - byhemechi on twitter or discord"
        }
      )
    end)

    Logger.info("Connected to squiggle #{channel}")

    %{state | channel: channel}
  end

  def handle_info(:check_connection, state) do
    Logger.warning("No messages received in the last minute, reconnecting stream")
    new_delay = min(state.retry_delay * 2, @max_retry_delay)

    Process.sleep(state.retry_delay)

    {:noreply,
     start_stream(%__MODULE__{state | retry_count: state.retry_count + 1, retry_delay: new_delay})}
  end

  def handle_info(
        {:squiggle_event, %{id: id, event: event, data: data}},
        %{channel: channel} = state
      )
      when is_binary(id) and is_binary(event) and is_binary(data) do
    with {:ok, data} <- JSON.decode(data) do
      Logger.info("Received #{event} event with ID #{id}")

      Phoenix.PubSub.broadcast(
        SquiggleRelay.PubSub,
        "squiggle_#{channel}",
        {:squiggle_event, channel, %SquiggleRelay.Event{id: id, event: event, data: data}}
      )
    end

    {:noreply, %{state | retry_count: 0}}
  end

  def handle_info({:squiggle_event, %{retry: retry_delay}}, state) when is_integer(retry_delay) do
    {:noreply, %{state | retry_delay: retry_delay}}
  end

  def handle_info({:squiggle_event, event}, state) do
    IO.inspect(event, label: "event fell through")
    {:noreply, state}
  end

  def handle_call(:get_state, _from, state) do
    {:reply, state, state}
  end

  def start_link(args \\ []) do
    channel = Keyword.get(args, :channel, :events)
    GenServer.start_link(__MODULE__, channel, args)
  end
end

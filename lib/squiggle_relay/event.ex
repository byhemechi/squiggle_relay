defmodule SquiggleRelay.Event do
  defstruct [:id, :event, :data]
end

defimpl JSON.Encoder, for: SquiggleRelay.Event do
  def encode(%SquiggleRelay.Event{id: id, event: event, data: data}, opts) do
    %{
      id: if(is_binary(id), do: id, else: UUID.uuid4()),
      event: String.Chars.to_string(event),
      data: data
    }
    |> JSON.Encoder.encode(opts)
  end
end

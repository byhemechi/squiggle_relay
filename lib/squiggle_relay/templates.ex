defmodule SquiggleRelay.Templates do
  for file <-
        Path.expand(__DIR__)
        |> Path.join("../../assets/templates/*.html")
        |> Path.wildcard() do
    filename = file |> Path.basename(".html") |> String.to_atom()

    def unquote(filename)(assigns \\ [])

    def unquote(filename)(assigns) when is_map(assigns) do
      unquote(filename)(Map.to_list(assigns))
    end

    def unquote(filename)(var!(assigns)) when is_list(assigns) do
      unquote(
        File.read!(file)
        |> String.split(~r/†.+?\b/, include_captures: true)
        |> Enum.with_index()
        |> Enum.map(fn
          {"†" <> code, index} when Bitwise.band(index, 1) == 1 ->
            quote do
              Access.get(
                var!(assigns),
                unquote(String.to_atom(code)),
                ""
              )
            end

          {code, _index} ->
            Macro.escape(code)
        end)
      )
    end
  end
end

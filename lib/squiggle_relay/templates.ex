defmodule SquiggleRelay.Templates do
  defmacro template(body) do
    file_data =
      body
      |> String.split(~r/<%.*?%>/, include_captures: true)

    file_data
  end

  for file <-
        Path.expand(__DIR__)
        |> Path.join("templates/*.html")
        |> Path.wildcard() do
    filename = Path.basename(file, ".html")

    defmacro render(unquote(filename)) do
      file_data =
        File.read!(unquote(file))

      [start | static_data] =
        Regex.split(~r/<%(?<call>.*?)%>/, file_data)

      code_block =
        Regex.scan(~r/<%(?<call>.*?)%>/, file_data, capture: [:call])

      zipped_template =
        Enum.zip(code_block, static_data)
        |> Enum.map(fn
          {[code], static} ->
            [
              Code.string_to_quoted!(code),
              static
            ]
        end)

      # Code.string_to_quoted!(code)

      [start | zipped_template]
    end
  end
end

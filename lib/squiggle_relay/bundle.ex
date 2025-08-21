defmodule SquiggleRelay.Bundle do
  defstruct scripts: [], styles: [], externals: %{}

  @bundle_info Path.expand(__DIR__)
               |> Path.join("./bundle.json")
               |> File.read!()
               |> JSON.decode!()

  @external_imports %{
    "squiggle_realtime" => "/lib/squiggle_realtime.js",
    "squiggle_realtime/client_data" => "/lib/client.js"
  }

  @outpath __DIR__ |> Path.join("../../priv/static") |> Path.expand()
  @asset_path __DIR__ |> Path.join("../../assets") |> Path.expand()

  for {output_path, %{"entryPoint" => entry_point, "imports" => imports} = bundle} <-
        @bundle_info["outputs"] do
    ext = Path.extname(output_path)

    relative_to_root = fn file ->
      basename = Path.basename(file)
      file = Path.join(@asset_path, file) |> Path.expand()
      file = Path.join("/", Path.relative_to(file, @outpath))

      if Regex.match?(~r/^.*\-[A-Z0-9]{8}\.*?$/, basename) do
        file <> "?vsn=d"
      else
        file
      end
    end

    def paths(unquote(entry_point)) do
      unquote(
        case ext do
          ".css" ->
            quote do
              %__MODULE__{
                styles: [
                  unquote(relative_to_root.(output_path))
                ]
              }
            end

          ".js" ->
            quote do
              %__MODULE__{
                scripts: [
                  unquote(relative_to_root.(output_path))
                ],
                externals:
                  unquote(
                    for %{"path" => path, "external" => true} <- imports do
                      {path, @external_imports[path]}
                    end
                    |> Enum.into(%{})
                    |> Macro.escape()
                  ),
                styles:
                  unquote(
                    case bundle do
                      %{"cssBundle" => css_bundle} ->
                        [relative_to_root.(css_bundle)]

                      _ ->
                        []
                    end
                  )
              }
            end
        end
      )
    end
  end

  def merge(chunks) when is_list(chunks) do
    chunks
    |> IO.inspect()
    |> Enum.reduce(%__MODULE__{}, fn chunk, acc ->
      %__MODULE__{
        scripts: acc.scripts ++ chunk.scripts,
        styles: acc.styles ++ chunk.styles,
        externals: Map.merge(acc.externals, chunk.externals)
      }
    end)
  end

  def render(%__MODULE__{scripts: scripts, styles: styles, externals: externals}) do
    %{
      scripts: [
        "<script type=\"importmap\">{\"imports\":",
        JSON.encode_to_iodata!(externals),
        "}</script>",
        for script <- scripts do
          ["<script type=\"module\" src=", JSON.encode_to_iodata!(script), "></script>"]
        end
      ],
      styles:
        for style <- styles do
          ["<link rel=\"stylesheet\" href=", JSON.encode_to_iodata!(style), " />"]
        end
    }
  end
end

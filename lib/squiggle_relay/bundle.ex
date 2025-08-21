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

  def append_immutable(path) do
    basename = Path.basename(path)

    if Regex.match?(~r/^.*\-[A-Z0-9]{8}\.*?$/, basename) do
      path <> "?vsn=d"
    else
      path
    end
  end

  for {output_path, %{"entryPoint" => entry_point, "imports" => imports} = bundle} <-
        @bundle_info["outputs"] do
    ext = Path.extname(output_path)

    output_path = Path.join(@asset_path, output_path) |> Path.expand()

    def paths(unquote(entry_point)) do
      unquote(
        case ext do
          ".css" ->
            quote do
              %__MODULE__{
                styles: [
                  unquote(Path.join("/", Path.relative_to(output_path, @outpath)) <> "?vsn=d")
                ]
              }
            end

          ".js" ->
            quote do
              %__MODULE__{
                scripts: [
                  unquote(Path.join("/", Path.relative_to(output_path, @outpath)) <> "?vsn=d")
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
                        css_bundle = Path.join(@asset_path, css_bundle) |> Path.expand()
                        [Path.join("/", Path.relative_to(css_bundle, @outpath)) <> "?vsn=d"]

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
    for %__MODULE{} = chunk <- chunks do
      chunk
    end
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

defmodule SquiggleRelay.Bundle.Rendered do
  defstruct head: [], body: []

  @doc false
  @spec fetch_assign!(Access.t(), Access.key()) :: term | nil
  def fetch_assign!(%__MODULE__{} = bundle, key) do
    case Map.get(bundle, key) do
      nil ->
        IO.warn("^#{key} is not a valid bundle section")

      v ->
        v
    end
  end
end

defimpl String.Chars, for: SquiggleRelay.Bundle.Rendered do
  def to_string(term) do
    map =
      term
      |> Map.from_struct()

    Map.values(map)
    |> case do
      [_ | _] = v ->
        IO.warn([
          "Rendering a bundle with multiple sections (",
          inspect(Map.keys(map)),
          "). This will put things where you probably don't expect them!"
        ])

        v

      v ->
        v
    end
    |> IO.chardata_to_string()
  end
end

defmodule SquiggleRelay.Bundle do
  defstruct scripts: [], styles: [], components: %{}, externals: %{}

  @external_resource Path.expand(__DIR__)
                     |> Path.join("../../priv/static/bundle.json")
                     |> Path.expand()

  @bundle_info @external_resource
               |> File.read!()
               |> JSON.decode!()

  @external_imports %{
    "squiggle_realtime" => "/lib/squiggle_realtime.js",
    "client_data" => "/lib/client.js"
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

    def resource(unquote(entry_point)) do
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
    |> List.flatten()
    |> Enum.reduce(%__MODULE__{}, fn
      %__MODULE__{} = chunk, acc ->
        %__MODULE__{
          scripts: acc.scripts ++ chunk.scripts,
          styles: acc.styles ++ chunk.styles,
          externals: Map.merge(acc.externals, chunk.externals),
          components: Map.merge(acc.components, chunk.components)
        }

      _, _ ->
        raise __MODULE__.InvalidChunk
    end)
  end

  def render(%__MODULE__{
        scripts: scripts,
        styles: styles,
        externals: externals,
        components: components
      }) do
    %__MODULE__.Rendered{
      body:
        [
          if(externals !== %{},
            do: [
              "<script type=\"importmap\">{\"imports\":",
              JSON.encode_to_iodata!(externals),
              "}</script>"
            ],
            else: ""
          ),
          if(components !== %{},
            do: [
              "<script type=\"module\">",
              for({name, path} <- components) do
                [
                  "import(",
                  JSON.encode_to_iodata!(path),
                  ").then(({default:c})=>customElements.define(",
                  JSON.encode_to_iodata!(name),
                  ",c));"
                ]
              end,
              "</script>"
            ],
            else: []
          ),
          for script <- Enum.uniq(scripts) do
            ["<script type=\"module\" src=", JSON.encode_to_iodata!(script), "></script>"]
          end
        ]
        |> IO.chardata_to_string(),
      head:
        for style <- Enum.uniq(styles) do
          [
            "<link rel=\"stylesheet\" href=",
            JSON.encode_to_iodata!(style),
            " type=\"text/css\"/>"
          ]
        end
        |> IO.chardata_to_string()
    }
  end

  def global_imports do
    [resource("app.css")]
  end
end

defmodule SquiggleRelay.Bundle.InvalidChunk do
  defexception message: "Chunk is not a bundle"
end

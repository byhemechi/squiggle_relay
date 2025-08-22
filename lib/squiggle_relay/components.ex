defmodule SquiggleRelay.Components do
  alias SquiggleRelay.Bundle

  def file_name_to_string(name) when is_binary(name) do
    name
    |> String.replace(~r/[^a-zA-Z]+/, "_")
    |> Macro.camelize()
  end

  for file <-
        __DIR__
        |> Path.join("../../assets/components/*/template.html")
        |> Path.expand()
        |> Path.wildcard() do
    filename = (dir = file |> Path.dirname()) |> Path.basename()

    bundle =
      dir
      |> Path.join("index.{t,j}s")
      |> Path.wildcard()
      |> Enum.map(&Path.relative_to(&1, Path.join(__DIR__, "../../assets")))
      |> Enum.take(1)
      |> Enum.map(&Bundle.resource/1)
      |> Bundle.merge()

    ast =
      File.read!(file)
      |> Floki.parse_document!(attributes_as_maps: true)
      |> Floki.find("template:root")
      |> Enum.map(fn {tag, attrs, children} ->
        {tag, Map.put_new(attrs, "shadowrootmode", "open"),
         for style <- bundle.styles do
           {"link", %{"rel" => "stylesheet", "type" => "text/css", "href" => style}, []}
         end ++ children}
      end)

    bundle =
      case bundle do
        %Bundle{scripts: [script]} ->
          %Bundle{
            bundle
            | components: %{
                filename => script
              },
              styles: [],
              scripts: []
          }

        _ ->
          %Bundle{
            styles: [],
            scripts: []
          }
      end

    def bundle_template(
          {unquote(filename), var!(attributes), var!(children)},
          %SquiggleRelay.Bundle{} = bundle
        ) do
      {{unquote(filename), attributes, unquote(Macro.escape(ast)) ++ children},
       Bundle.merge([bundle, unquote(Macro.escape(bundle))])}
    end
  end

  def bundle_template(component, asset_bundle), do: {component, asset_bundle}

  def bundle_template(component), do: bundle_template(component, %Bundle{}) |> elem(0)
end

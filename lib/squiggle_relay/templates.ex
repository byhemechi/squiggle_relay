defmodule SquiggleRelay.Templates do
  alias SquiggleRelay.Bundle

  for file <-
        Path.expand(__DIR__)
        |> Path.join("../../assets/templates/*.eex")
        |> Path.wildcard() do
    filename = file |> Path.basename(".eex")

    {template, component_deps} =
      case Path.extname(filename) do
        ".html" ->
          {document, deps} =
            File.read!(file)
            |> Floki.parse_document!()
            |> Floki.traverse_and_update(%Bundle{}, &SquiggleRelay.Components.bundle_template/2)

          {"<!doctype html>" <> Floki.raw_html(document, encode: false), deps}

        _ ->
          {File.read!(file), []}
      end

    filename = String.to_atom(filename)

    template =
      template |> EEx.compile_string(engine: SquiggleRelay.TemplateEngine, file: file, line: 1)

    def unquote(filename)(assigns \\ [], dependencies \\ %Bundle{})

    def unquote(filename)(assigns, dependencies) when is_map(assigns) do
      unquote(filename)(dependencies, Map.to_list(assigns))
    end

    def unquote(filename)(var!(assigns), var!(dependencies))
        when is_list(assigns) and
               is_struct(dependencies) and
               dependencies.__struct__ == Bundle do
      var!(dependencies) =
        Bundle.merge([
          unquote(Macro.escape([component_deps | Bundle.global_imports()])),
          dependencies
        ])
        |> Bundle.render()

      unquote(template)
    end
  end
end

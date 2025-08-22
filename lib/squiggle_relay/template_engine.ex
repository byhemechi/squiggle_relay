# SPDX-License-Identifier: Apache-2.0
# SPDX-FileCopyrightText: 2021 The Elixir Team
# SPDX-FileCopyrightText: 2012 Plataformatec

defmodule SquiggleRelay.TemplateEngine do
  @moduledoc """
  The default engine used by EEx.

  It includes assigns (like `@foo`) and possibly other
  conveniences in the future.

  ## Examples

      iex> EEx.eval_string("<%= @foo %>", assigns: [foo: 1])
      "1"

  In the example above, we can access the value `foo` under
  the binding `assigns` using `@foo`. This is useful because
  a template, after being compiled, can receive different
  assigns and would not require recompilation for each
  variable set.

  Assigns can also be used when compiled to a function:

      # sample.eex
      <%= @a + @b %>

      # sample.ex
      defmodule Sample do
        require EEx
        EEx.function_from_file(:def, :sample, "sample.eex", [:assigns])
      end

      # iex
      Sample.sample(a: 1, b: 2)
      #=> "3"

  """

  @behaviour EEx.Engine

  @impl true
  defdelegate init(opts), to: EEx.Engine

  @impl true
  defdelegate handle_body(state), to: EEx.Engine

  @impl true
  defdelegate handle_begin(state), to: EEx.Engine

  @impl true
  defdelegate handle_end(state), to: EEx.Engine

  @impl true
  defdelegate handle_text(state, meta, text), to: EEx.Engine

  @spec handle_assign(Macro.t()) :: Macro.t()
  def handle_assign({:^, meta, [{name, _, atom}]}) when is_atom(name) and is_atom(atom) do
    line = meta[:line] || 0

    quote(
      line: line,
      do: SquiggleRelay.Bundle.Rendered.fetch_assign!(var!(dependencies), unquote(name))
    )
  end

  defdelegate handle_assign(arg), to: EEx.Engine

  @impl true
  def handle_expr(state, marker, expr) do
    expr = Macro.prewalk(expr, &handle_assign/1)

    EEx.Engine.handle_expr(state, marker, expr)
  end
end

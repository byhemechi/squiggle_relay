defmodule SquiggleRelay.Games do
  use GenServer

  def init(_init_arg) do
    table = :ets.new(:games, [:set, :protected, :named_table])
    {:ok, table}
  end

  def start_link(args \\ []) do
    GenServer.start_link(__MODULE__, [], args)
  end
end

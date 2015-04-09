defmodule Mix.Tasks.Upgrade do
  use Mix.Task
  alias Mnesia.Cache, as: Cache
  use Cache

  def run(_) do
    Amnesia.start
    # ... upgrade here
    Amnesia.stop
  end
end

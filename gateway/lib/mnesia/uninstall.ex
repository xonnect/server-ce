defmodule Mix.Tasks.UninstallMnesia do
  use Mix.Task
  alias Mnesia.Cache, as: Cache
  use Cache

  def run(_) do
    Amnesia.start
    Cache.destroy
    Amnesia.stop
    Amnesia.Schema.destroy
  end
end

defmodule Mix.Tasks.InstallMnesia do
  use Mix.Task
  alias Mnesia.Cache, as: Cache
  use Cache

  def run(_) do
    # This creates the mnesia schema, this has to be done on every node before
    # starting mnesia itself, the schema gets stored on disk based on the
    # `-mnesia` config, so you don't really need to create it every time.
    Amnesia.Schema.create
    Amnesia.start

    Cache.create! memory: [node]
    Cache.wait

    Amnesia.transaction do
      # ... initial data creation
    end
    Amnesia.stop
  end
end

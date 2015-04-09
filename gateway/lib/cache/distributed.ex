defmodule Cache.Distributed do
  alias Mnesia.Cache.Map, as: Map

  def put(key, value) do
    %Map{key: key, value: value} |> Map.write!
  end

  def remove(key) do
    Map.delete! key
  end

  def get(key, default \\ nil) do
    result = Map.read! key
    case result do
      nil -> default
      _otherwise -> result.value
    end
  end
end

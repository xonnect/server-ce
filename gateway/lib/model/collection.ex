defmodule Model.Collection do
  def get(collection, key) when is_map(collection) do
    Map.get collection, key, nil
  end

  def get(collection, key) when is_list(collection) do
    :proplists.get_value key, collection, nil
  end

  def get(collection, key, default) when is_map(collection) do
    Map.get collection, key, default
  end

  def get(collection, key, default) when is_list(collection) do
    :proplists.get_value key, collection, default
  end
end

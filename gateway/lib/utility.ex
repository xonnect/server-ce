defmodule Utility do
  def random_id() do
    :crypto.hash(:sha, :uuid.get_v4)
    |> Base.encode16 |> String.downcase
  end
end

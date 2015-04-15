defmodule Utility do
  def random_id() do
    :crypto.hash(:sha, :uuid.get_v4)
    |> Base.encode16 |> String.downcase
  end

  def encode_body(:json, code, info) do
    do_encode_json(code, info, nil)
  end

  def encode_body(:bson, code, info) do
    do_encode_bson(code, info, nil)
  end

  def encode_body(:json, code, info, data) do
    do_encode_json(code, info, data)
  end

  def encode_body(:bson, code, info, data) do
    do_encode_bson(code, info, data)
  end

  defp do_encode_json(code, info, data) do
    response = [
      code: code,
      info: info,
      data: data
    ]
    response = Enum.filter response, fn({_k, v}) -> v != nil end
    :jsx.encode response
  end

  defp do_encode_bson(code, info, data) do
    response = %{
      code: code,
      info: info,
      data: data
    }
    response = Enum.filter response, fn({_k, v}) -> v != nil end
    Bson.encode response
  end
end

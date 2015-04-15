defmodule Handler.Message do
  use Cowboy.HTTP
  alias Model.Collection, as: Collection
  alias Nick.Agent, as: Nick
  alias Channel.Agent, as: Channel

  def handle(request, state) do
    {method, request1} = :cowboy_req.method(request)
    do_handle(method, request1, state)
  end

  defp do_handle("POST", request, state) do
    {:ok, data, request1} = :cowboy_req.body(request)
    try do
      collection = :jsx.decode data
      target = Collection.get collection, "target"
      true = target != nil
      true = String.length(target) > 1
      data = Collection.get collection, "data"
      true = data != nil
      case String.first target do
        "@" ->
          nick = String.slice target, 1..-1
          Nick.send "~unknown", nick, data
        "#" ->
          channel = String.slice target, 1..-1
          Channel.broadcast channel, data
      end
      {:ok, request2} = :cowboy_req.reply(201, request1)
      {:ok, request2, state}
    rescue
      _whatever ->
        body = Utility.encode_body :json, "error", "bad.request"
        {:ok, request2} = :cowboy_req.reply(400, [
          {"content-type", "application/json; charset=utf-8"}
        ], body, request1)
        {:ok, request2, state}
    end
  end

  defp do_handle(method, request, state) do
    body = Utility.encode_body :json, "error", "unsupported.method", method
    {:ok, request1} = :cowboy_req.reply(400, [
      {"content-type", "application/json; charset=utf-8"}
    ], body, request)
    {:ok, request1, state}
  end
end

defmodule Handler.Socket do
  import Model.Record
  require Lager
  @bahaviour :sockjs_service

  fields socket: nil,
         ip_address: nil

  def sockjs_init(connection, []) do
    [{:headers, headers}] = Enum.filter connection.info, fn({k, _v}) -> k == :headers end
    [{:'x-real-ip', ip_address}] = Enum.filter headers, fn({k, _v}) -> k == :'x-real-ip' end
    Lager.info "[handler.socket/sockjs_init] socket ip address: ~p", [ip_address]
    socket_info = new socket: self, ip_address: ip_address
    {:ok, {:unknown, socket_info}}
  end

  def sockjs_handle(connection, data, {:unknown, socket_info}) do
    Lager.debug "[handler.socket/sockjs_handle] socket info: ~p", [socket_info]
    try do
      list = :jsx.decode data
      try do
        action = :proplists.get_value "action", list
        true = action != :undefined
        do_handle connection, action, list, {:json, socket_info}
      rescue
        _whatever ->
          Lager.debug "[handler.socket/sockjs_handle] bad json request"
          body = encode_body :json, "error", "bad.request", :null
          connection.send body
          {:ok, {:json, socket_info}}
      end
    rescue
      _whatever ->
        try do
          map = Bson.decode data
          action = map.action
          do_handle connection, action, map, {:bson, socket_info}
        rescue
          _whatever ->
            Lager.debug "[handler.socket/sockjs_handle] bad bson request"
            body = encode_body :bson, "error", "bad.request", :null
            connection.send body
            {:ok, {:bson, socket_info}}
        end
    end
  end

  def sockjs_handle(connection, json, state={:json, socket_info}) do
    Lager.debug "[handler.socket/sockjs_handle] socket info: ~p", [socket_info]
    try do
      list = :jsx.decode json
      action = :proplists.get_value "action", list
      true = action != :undefined
      do_handle connection, action, list, state
    rescue
      _whatever ->
        Lager.debug "[handler.socket/sockjs_handle] bad json request"
        body = encode_body :json, "error", "bad.request", :null
        connection.send body
        {:ok, state}
    end
  end

  def sockjs_handle(connection, bson, state={:bson, socket_info}) do
    Lager.debug "[handler.socket/sockjs_handle] socket info: ~p", [socket_info]
    try do
      map = Bson.decode bson
      action = map.action
      do_handle connection, action, map, state
    rescue
      _whatever ->
        Lager.debug "[handler.socket/sockjs_handle] bad bson request"
        body = encode_body :bson, "error", "bad.request", :null
        connection.send body
        {:ok, state}
    end
  end

  defp do_handle(connection, action, _collection, state={interface, _}) do
    Lager.debug "[handler.socket/do_handle] request action: ~p", [action]
    body = encode_body interface, "error", "unsupported.action", action
    connection.send body
    {:ok, state}
  end

  def sockjs_info(_connection, _info, state) do
    {:ok, state}
  end

  def sockjs_terminate(_connection, state) do
    {:ok, state}
  end

  defp encode_body(:json, code, info, data) do
    response = [
      code: code,
      info: info,
      data: data
    ]
    response = Enum.filter response, fn({_k, v}) -> v != :null end
    :jsx.encode response
  end

  defp encode_body(:bson, code, info, data) do
    response = %{
      code: code,
      info: info,
      data: data
    }
    response = Enum.filter response, fn({_k, v}) -> v != :null end
    Bson.encode response
  end
end

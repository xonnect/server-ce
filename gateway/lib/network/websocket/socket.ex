defmodule Network.Websocket.Socket do
  alias Model.Collection, as: Collection
  alias Nick.Agent, as: Nick
  alias Channel.Agent, as: Channel
  import Model.Record
  require Lager
  @bahaviour :sockjs_service

  fields nick: nil

  def sockjs_init(_connection, []) do
    socket_info = new
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
          body = Utility.encode_body :json, "error", "bad.request"
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
            body = Utility.encode_body :bson, "error", "bad.request"
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
        body = Utility.encode_body :json, "error", "bad.request"
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
        body = Utility.encode_body :bson, "error", "bad.request"
        connection.send body
        {:ok, state}
    end
  end

  defp do_handle(connection, "register", collection, {interface, socket_info}) do
    case socket_info.nick do
      nil ->
        result = Collection.get collection, "nick"
        case result do
          nil ->
            {:ok, nick} = Nick.register
            socket_info = socket_info.update nick: nick
            body = Utility.encode_body interface, "ok", "register.ok", nick
            connection.send body
          nick ->
            try do
              {:ok, nick} = Nick.register nick
              socket_info = socket_info.update nick: nick
              body = Utility.encode_body interface, "ok", "register.ok", nick
              connection.send body
            rescue
              _whatever ->
                body = Utility.encode_body interface, "error", "register.conflict", nick
                connection.send body
            end
        end
      nick ->
        body = Utility.encode_body interface, "ok", "register.ok", nick
        connection.send body
    end
    {:ok, {interface, socket_info}}
  end

  defp do_handle(connection, "send", collection, {interface, socket_info}) do
    if socket_info.nick == nil do
      {:ok, nick} = Nick.register
      body = Utility.encode_body interface, "ok", "register.ok", nick
      connection.send body
      socket_info = socket_info.update nick: nick
    end

    target = Collection.get collection, "target"
    true = target != nil
    true = String.length(target) > 1
    data = Collection.get collection, "data"
    true = data != nil
    ref = Collection.get collection, "ref"
    case String.first target do
      "@" ->
        nick = String.slice target, 1..-1
        Nick.send "@" <> socket_info.nick, nick, data
      "#" ->
        channel = String.slice target, 1..-1
        Channel.broadcast channel, data, self
    end
    if ref != nil do
      body = Utility.encode_body interface, "ok", "send.ok", [ref: ref]
      connection.send body
    end
    {:ok, {interface, socket_info}}
  end

  defp do_handle(connection, "subscribe", collection, {interface, socket_info}) do
    channel = Collection.get collection, "channel"
    true = channel != nil
    :ok = Channel.subscribe channel, socket_info
    body = Utility.encode_body interface, "ok", "subscribe.ok", channel
    connection.send body
    {:ok, {interface, socket_info}}
  end

  defp do_handle(connection, "unsubscribe", collection, {interface, socket_info}) do
    channel = Collection.get collection, "channel"
    true = channel != nil
    :ok = Channel.unsubscribe channel, socket_info
    body = Utility.encode_body interface, "ok", "unsubscribe.ok", channel
    connection.send body
    {:ok, {interface, socket_info}}
  end

  defp do_handle(connection, action, _collection, state={interface, _}) do
    body = Utility.encode_body interface, "error", "unsupported.action", action
    connection.send body
    {:ok, state}
  end

  def sockjs_info(connection, {:direct_message, from, data}, state={interface, _}) do
    body = Utility.encode_body interface, "new", [from: from], data
    connection.send body
    {:ok, state}
  end

  def sockjs_info(connection, {:channel_message, from, data}, state={interface, _}) do
    body = Utility.encode_body interface, "new", [from: from], data
    connection.send body
    {:ok, state}
  end

  def sockjs_info(_connection, _info, state) do
    {:ok, state}
  end

  def sockjs_terminate(_connection, state) do
    {:ok, state}
  end
end

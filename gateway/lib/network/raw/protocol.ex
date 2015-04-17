defmodule Network.Raw.Protocol do
  alias Model.Collection, as: Collection
  alias Nick.Agent, as: Nick
  alias Channel.Agent, as: Channel
  import Model.Record
  use GenServer
  require Lager

  fields socket: nil,
         transport: nil,
         nick: nil

  # GenServer api
  def start_link(ref, socket, transport, options) do
    :proc_lib.start_link(__MODULE__, :init, [ref, socket, transport, options])
  end

  # GenServer callbacks
  def init([]) do
    {:ok, nil}
  end

  def init(ref, socket, transport, _options) do
    :ok = :proc_lib.init_ack {:ok, self}
    :ok = :ranch.accept_ack ref
    :ok = transport.setopts socket, [active: :once]
    info = new socket: socket, transport: transport
    :gen_server.enter_loop __MODULE__, [], {:unknown, info}
  end

  def handle_info({:tcp, _socket, data}, state) do
    Lager.debug "[network.raw.protocol/handle_info] state: ~p", [state]
    handle_data data, state
  end

  def handle_info({:ssl, _socket, data}, state) do
    Lager.debug "[network.raw.protocol/handle_info] state: ~p", [state]
    handle_data data, state
  end

  def handle_info({:tcp_closed, _socket}, state) do
    {:stop, :normal, state}
  end

  def handle_info({:ssl_closed, _socket}, state) do
    {:stop, :normal, state}
  end

  def handle_info({:tcp_error, _socket, reason}, state) do
    {:stop, reason, state}
  end

  def handle_info({:ssl_error, _socket, reason}, state) do
    {:stop, reason, state}
  end

  def handle_info({:direct_message, from, data}, state={interface, info}) do
    socket = info.socket
    transport = info.transport
    body = Utility.encode_body interface, "new", [from: from], data
    transport.send socket, body
    {:noreply, state}
  end

  def handle_info({:channel_message, from, data}, state={interface, info}) do
    socket = info.socket
    transport = info.transport
    body = Utility.encode_body interface, "new", [from: from], data
    transport.send socket, body
    {:noreply, state}
  end

  defp handle_data(data, {:unknown, info}) do
    socket = info.socket
    transport = info.transport
    :ok = transport.setopts socket, [active: :once]
    try do
      list = :jsx.decode data
      try do
        action = :proplists.get_value "action", list
        true = action != :undefined
        do_handle socket, transport, action, list, {:json, info}
      rescue
        _whatever ->
          Lager.debug "[network.raw.protocol/handle_data] bad json request"
          body = Utility.encode_body :json, "error", "bad.request"
          transport.send socket, body
          {:noreply, {:json, info}}
      end
    rescue
      _whatever ->
        try do
          map = Bson.decode data
          action = map.action
          do_handle socket, transport, action, map, {:bson, info}
        rescue
          _whatever ->
            Lager.debug "[network.raw.protocol/handle_data] bad bson request"
            body = Utility.encode_body :bson, "error", "bad.request"
            transport.send socket, body
            {:noreply, {:bson, info}}
        end
    end
  end

  defp handle_data(json, {:json, info}) do
    socket = info.socket
    transport = info.transport
    :ok = transport.setopts socket, [active: :once]
    try do
      list = :jsx.decode json
      action = :proplists.get_value "action", list
      true = action != :undefined
      do_handle socket, transport, action, list, {:json, info}
    rescue
      _whatever ->
        Lager.debug "[network.raw.protocol/handle_data] bad json request"
        body = Utility.encode_body :json, "error", "bad.request"
        transport.send socket, body
        {:noreply, {:json, info}}
    end
  end

  defp handle_data(bson, {:bson, info}) do
    socket = info.socket
    transport = info.transport
    :ok = transport.setopts socket, [active: :once]
    try do
      map = Bson.decode bson
      action = map.action
      true = action != :undefined
      do_handle socket, transport, action, map, {:bson, info}
    rescue
      _whatever ->
        Lager.debug "[network.raw.protocol/handle_data] bad bson request"
        body = Utility.encode_body :bson, "error", "bad.request"
        transport.send socket, body
        {:noreply, {:bson, info}}
    end
  end

  defp do_handle(socket, transport, "register", collection, {interface, info}) do
    case info.nick do
      nil ->
        result = Collection.get collection, "nick"
        case result do
          nil ->
            {:ok, nick} = Nick.register
            info = info.update nick: nick
            body = Utility.encode_body interface, "ok", "register.ok", nick
            transport.send socket, body
          nick ->
            try do
              {:ok, nick} = Nick.register nick
              info = info.update nick: nick
              body = Utility.encode_body interface, "ok", "register.ok", nick
              transport.send socket, body
            rescue
              _whatever ->
                body = Utility.encode_body interface, "error", "register.conflict", nick
                transport.send socket, body
            end
        end
      nick ->
        body = Utility.encode_body interface, "ok", "register.ok", nick
        transport.send socket, body
    end
    {:noreply, {interface, info}}
  end

  defp do_handle(socket, transport, "send", collection, {interface, info}) do
    if info.nick == nil do
      {:ok, nick} = Nick.register
      body = Utility.encode_body interface, "ok", "register.ok", nick
      transport.send socket, body
      info = info.update nick: nick
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
        Nick.send "@" <> info.nick, nick, data
      "#" ->
        channel = String.slice target, 1..-1
        Channel.broadcast channel, data, self
    end
    if ref != nil do
      body = Utility.encode_body interface, "ok", "send.ok", [ref: ref]
      transport.send socket, body
    end
    {:noreply, {interface, info}}
  end

  defp do_handle(socket, transport, "subscribe", collection, {interface, info}) do
    channel = Collection.get collection, "channel"
    true = channel != nil
    :ok = Channel.subscribe channel, info
    body = Utility.encode_body interface, "ok", "subscribe.ok", channel
    transport.send socket, body
    {:noreply, {interface, info}}
  end

  defp do_handle(socket, transport, "unsubscribe", collection, {interface, info}) do
    channel = Collection.get collection, "channel"
    true = channel != nil
    :ok = Channel.unsubscribe channel, info
    body = Utility.encode_body interface, "ok", "unsubscribe.ok", channel
    transport.send socket, body
    {:noreply, {interface, info}}
  end

  defp do_handle(socket, transport, action, _collection, state={interface, _}) do
    body = Utility.encode_body interface, "error", "unsupported.action", action
    transport.send socket, body
    {:noreply, state}
  end
end

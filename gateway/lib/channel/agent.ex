defmodule Channel.Agent do
  alias Cache.Distributed, as: Cache
  alias Channel.Supervisor, as: Supervisor
  import Model.Record
  use GenServer
  require Lager

  fields identifier: nil,
         sockets: nil

  # GenServer api
  def start_link(identifier) do
    GenServer.start_link(__MODULE__, [identifier], [])
  end

  # api
  defp get(identifier) do
    result = Cache.get {:channel, identifier}
    case result do
      nil ->
        {:ok, pid} = Supervisor.start_child identifier
        Cache.put {:channel, identifier}, pid
        {:ok, pid}
      pid ->
        {:ok, pid}
    end
  end

  def subscribe(identifier, socket_info) do
    {:ok, pid} = get(identifier)
    GenServer.call pid, {:subscribe, socket_info}
  end

  def unsubscribe(identifier, socket_info) do
    {:ok, pid} = get(identifier)
    GenServer.cast pid, {:unsubscribe, socket_info}
  end

  def broadcast(identifier, data) do
    {:ok, pid} = get(identifier)
    GenServer.cast pid, {:broadcast, data}
  end

  def broadcast(identifier, data, socket_info) do
    {:ok, pid} = get(identifier)
    GenServer.cast pid, {:broadcast, data, socket_info}
  end

  # GenServer callbacks
  def init([identifier]) do
    Lager.debug "[channel.agent/init] channel ~p is created", [identifier]
    channel_info = new identifier: identifier, sockets: :orddict.new
    {:ok, channel_info}
  end

  def handle_call({:subscribe, socket_info}, _from, channel_info) do
    socket = socket_info.socket
    sockets = channel_info.sockets
    result = :orddict.find(socket, sockets)
    case result do
      {:ok, _} ->
        Lager.debug "[channel.agent/handle_call] ~p is already in channel ~p", [socket, channel_info.identifier]
        {:reply, :ok, channel_info}
      :error ->
        socket_ref = :erlang.monitor :process, socket
        sockets = :orddict.store socket, {socket_ref, socket_info}, sockets
        channel_info = channel_info.update sockets: sockets
        Lager.debug "[channel.agent/handle_call] ~p joins channel ~p", [socket, channel_info.identifier]
        {:reply, :ok, channel_info}
    end
  end

  def handle_cast({:unsubscribe, socket_info}, channel_info) do
    socket = socket_info.socket
    sockets = channel_info.sockets
    {socket_ref, _} = :orddict.fetch socket, sockets
    true = :erlang.demonitor socket_ref
    sockets = :orddict.erase socket, sockets
    channel_info = channel_info.update sockets: sockets
    Lager.debug "[channel.agent/handle_cast] ~p leaves channel ~p", [socket, channel_info.identifier]
    case :orddict.is_empty(sockets) do
      true ->
        Cache.remove {:channel, channel_info.identifier}
        {:stop, :normal, channel_info}
      false ->
        {:noreply, channel_info}
    end
  end

  def handle_cast({:broadcast, data}, channel_info) do
    sockets = channel_info.sockets
    message = {:channel_message, "#" <> channel_info.identifier, data}
    sockets |> Enum.map fn({socket_pid, _}) ->
      send socket_pid, message
    end
    {:noreply, channel_info}
  end

  def handle_cast({:broadcast, data, socket_info}, channel_info) do
    socket = socket_info.socket
    sockets = channel_info.sockets
    message = {:channel_message, "#" <> channel_info.identifier, data}
    sockets |> Enum.map fn({socket_pid, _}) ->
      if socket == socket_pid do
        :ok
      else
        send socket_pid, message
      end
    end
    {:noreply, channel_info}
  end

  def handle_info({:'DOWN', _, _, socket, _}, channel_info) do
    Lager.debug "[channel.agent/handle_info] ~p loses connection to channel ~p", [socket, channel_info.identifier]
    sockets = channel_info.sockets
    sockets = :orddict.erase socket, sockets
    channel_info = channel_info.update sockets: sockets
    case :orddict.is_empty(sockets) do
      true ->
        Cache.remove {:channel, channel_info.identifier}
        {:stop, :normal, channel_info}
      false ->
        {:noreply, channel_info}
    end
  end

  def handle_info(_info, state) do
    {:noreply, state}
  end

  def terminate(_reason, channel_info) do
    Lager.debug "[channel.agent/terminate] channel ~p is removed", [channel_info.identifier]
    :ok
  end
end

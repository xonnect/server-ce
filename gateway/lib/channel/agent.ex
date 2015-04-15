defmodule Channel.Agent do
  alias Cache.Distributed, as: Cache
  alias Channel.Supervisor, as: Supervisor
  import Model.Record
  use GenServer
  require Lager

  fields identifier: nil,
         pids: nil

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

  def subscribe(identifier, pid) do
    {:ok, ch} = get(identifier)
    GenServer.call ch, {:subscribe, pid}
  end

  def unsubscribe(identifier, pid) do
    {:ok, ch} = get(identifier)
    GenServer.cast ch, {:unsubscribe, pid}
  end

  def broadcast(identifier, data) do
    {:ok, ch} = get(identifier)
    GenServer.cast ch, {:broadcast, data}
  end

  def broadcast(identifier, data, pid) do
    {:ok, ch} = get(identifier)
    GenServer.cast ch, {:broadcast, data, pid}
  end

  # GenServer callbacks
  def init([identifier]) do
    Lager.debug "[channel.agent/init] channel ~p is created", [identifier]
    channel_info = new identifier: identifier, pids: :orddict.new
    {:ok, channel_info}
  end

  def handle_call({:subscribe, pid}, _from, channel_info) do
    pids = channel_info.pids
    result = :orddict.find(pid, pids)
    case result do
      {:ok, _} ->
        Lager.debug "[channel.agent/handle_call] ~p is already in channel ~p", [pid, channel_info.identifier]
        {:reply, :ok, channel_info}
      :error ->
        pid_ref = :erlang.monitor :process, pid
        pids = :orddict.store pid, {pid_ref, pid}, pids
        channel_info = channel_info.update pids: pids
        Lager.debug "[channel.agent/handle_call] ~p joins channel ~p", [pid, channel_info.identifier]
        {:reply, :ok, channel_info}
    end
  end

  def handle_cast({:unsubscribe, pid}, channel_info) do
    pids = channel_info.pids
    {pid_ref, _} = :orddict.fetch pid, pids
    true = :erlang.demonitor pid_ref
    pids = :orddict.erase pid, pids
    channel_info = channel_info.update pids: pids
    Lager.debug "[channel.agent/handle_cast] ~p leaves channel ~p", [pid, channel_info.identifier]
    case :orddict.is_empty(pids) do
      true ->
        Cache.remove {:channel, channel_info.identifier}
        {:stop, :normal, channel_info}
      false ->
        {:noreply, channel_info}
    end
  end

  def handle_cast({:broadcast, data}, channel_info) do
    pids = channel_info.pids
    message = {:channel_message, "#" <> channel_info.identifier, data}
    pids |> Enum.map fn({pid, _}) ->
      send pid, message
    end
    {:noreply, channel_info}
  end

  def handle_cast({:broadcast, data, pid}, channel_info) do
    pids = channel_info.pids
    message = {:channel_message, "#" <> channel_info.identifier, data}
    pids |> Enum.map fn({p, _}) ->
      if pid == p do
        :ok
      else
        send pid, message
      end
    end
    {:noreply, channel_info}
  end

  def handle_info({:'DOWN', _, _, pid, _}, channel_info) do
    Lager.debug "[channel.agent/handle_info] ~p loses connection to channel ~p", [pid, channel_info.identifier]
    pids = channel_info.pids
    pids = :orddict.erase pid, pids
    channel_info = channel_info.update pids: pids
    case :orddict.is_empty(pids) do
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

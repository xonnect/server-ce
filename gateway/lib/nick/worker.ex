defmodule Nick.Worker do
  alias Cache.Distributed, as: Cache
  require Lager
  use GenServer
  @behaviour :poolboy_worker

  # poolboy callback
  def start_link([]) do
    GenServer.start_link __MODULE__, [], []
  end
  
  # GenServer callbacks
  def handle_call(:register, {socket, _}, state) do
    nick = Utility.random_id
    Cache.put {:nick, nick}, socket
    Cache.put {:socket, socket}, nick
    :erlang.monitor :process, socket
    {:reply, {:ok, nick}, state}
  end

  def handle_call({:register, nick}, {socket, _}, state) do
    result = Cache.get {:nick, nick}
    case result do
      nil ->
        Cache.put {:nick, nick}, socket
        Cache.put {:socket, socket}, nick
        :erlang.monitor :process, socket
        {:reply, {:ok, nick}, state}
      _other ->
        {:reply, :conflict_nick, state}
    end
  end

  def handle_info({:'DOWN', _, _, socket, _}, state) do
    Lager.debug "[nick.worker/handle_info] socket ~p lost connection", [socket]
    nick = Cache.get {:socket, socket}
    Cache.remove {:socket, socket}
    Cache.remove {:nick, nick}
    {:noreply, state}
  end
end

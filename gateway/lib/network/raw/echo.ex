defmodule Network.Raw.Echo do
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
    state = new socket: socket, transport: transport
    :gen_server.enter_loop __MODULE__, [], state
  end

  def handle_info({:tcp, _socket, data}, state) do
    socket = state.socket
    transport = state.transport
    :ok = transport.setopts socket, [active: :once]
    handle_data data, socket, transport
    {:noreply, state}
  end

  def handle_info({:ssl, _socket, data}, state) do
    socket = state.socket
    transport = state.transport
    :ok = transport.setopts socket, [active: :once]
    handle_data data, socket, transport
    {:noreply, state}
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

  defp handle_data(data, socket, transport) do
    transport.send socket, data
  end
end

defmodule Network.Raw.TCP.Supervisor do
  use Supervisor

  # Supervisor api
  def start_link(tcp_port) do
    Supervisor.start_link __MODULE__, tcp_port, name: __MODULE__
  end

  # Supervisor callback
  def init(tcp_port) do
    children = [
      worker(:ranch, [
        :tcp_interface, 8,
        :ranch_tcp,
        [{:port, tcp_port}, {:max_connections, :infinity}],
        Network.Raw.Protocol, []
      ], function: :start_listener)
    ]
    supervise children, strategy: :one_for_one, max_restarts: 10, max_seconds: 10
  end
end

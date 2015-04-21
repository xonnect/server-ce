defmodule Network.Raw.TCP.Supervisor do
  use Supervisor

  # Supervisor api
  def start_link() do
    Supervisor.start_link __MODULE__, [], name: __MODULE__
  end

  # Supervisor callback
  def init([]) do
    tcp = Application.get_env(:gateway, :tcp_interface)
    tcp_port = tcp[:port]
    listener_num = tcp[:listener_num]

    children = [
      worker(:ranch, [
        :tcp_interface, listener_num,
        :ranch_tcp,
        [{:port, tcp_port}, {:max_connections, :infinity}],
        Network.Raw.Protocol, []
      ], function: :start_listener)
    ]
    supervise children, strategy: :one_for_one, max_restarts: 10, max_seconds: 10
  end
end

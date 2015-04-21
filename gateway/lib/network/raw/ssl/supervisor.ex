defmodule Network.Raw.SSL.Supervisor do
  use Supervisor

  # Supervisor api
  def start_link() do
    Supervisor.start_link __MODULE__, [], name: __MODULE__
  end

  # Supervisor callback
  def init([]) do
    ssl = Application.get_env(:gateway, :ssl_interface)
    ssl_port = ssl[:port]
    listener_num = ssl[:listener_num]

    privdir = :code.priv_dir(:gateway)
    children = [
      worker(:ranch, [
        :ssl_interface, listener_num,
        :ranch_ssl, [
          port: ssl_port,
          max_connections: :infinity,
          cacertfile: privdir ++ '/ssl/ca.crt',
          certfile: privdir ++ '/ssl/server.crt',
          keyfile: privdir ++ '/ssl/server.key'
        ],
        Network.Raw.Protocol, []
      ], function: :start_listener)
    ]
    supervise children, strategy: :one_for_one, max_restarts: 10, max_seconds: 10
  end
end

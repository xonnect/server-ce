defmodule Network.Raw.SSL.Supervisor do
  use Supervisor

  # Supervisor api
  def start_link(ssl_port) do
    Supervisor.start_link __MODULE__, ssl_port, name: __MODULE__
  end

  # Supervisor callback
  def init(ssl_port) do
    privdir = :code.priv_dir(:gateway)
    children = [
      worker(:ranch, [
        :ssl_interface, 8,
        :ranch_ssl, [
          port: ssl_port,
          max_connections: :infinity,
          cacertfile: privdir ++ '/ssl/ca.crt',
          certfile: privdir ++ '/ssl/server.crt',
          keyfile: privdir ++ '/ssl/server.key'
        ],
        Network.Raw.Echo, []
      ], function: :start_listener)
    ]
    supervise children, strategy: :one_for_one, max_restarts: 10, max_seconds: 10
  end
end

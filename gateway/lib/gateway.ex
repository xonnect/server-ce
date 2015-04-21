defmodule XonnectGateway do
  use Application

  def start(_type, _args) do
    import Supervisor.Spec, warn: false

    cowboy = Application.get_env(:gateway, :cowboy)
    domain = cowboy[:domain]
    http_port = cowboy[:port]
    listener_num = cowboy[:listener_num]

    websocket = :sockjs_handler.init_state("/api/v1", Network.Websocket.Socket, [], [])

    dispatch = :cowboy_router.compile([
      {domain, [
        {"/assets/[...]", :cowboy_static, {
          :priv_dir, :gateway, "assets", [{:mimetypes, :cow_mimetypes, :all}]
        }},
        {"/api/v1/messages", Network.HTTP.Message, []},
        {"/api/v1/websocket", :sockjs_cowboy_handler, websocket}
      ]},
      {"unsafe." <> domain, [
        {"/assets/[...]", :cowboy_static, {
          :priv_dir, :gateway, "assets", [{:mimetypes, :cow_mimetypes, :all}]
        }},
        {"/api/v1/messages", Network.HTTP.Message, []},
        {"/api/v1/websocket", :sockjs_cowboy_handler, websocket}
      ]}
    ])

    cowboy_args = [:http, listener_num,
      [port: http_port],
      [env: [dispatch: dispatch]]
    ]

    children = [
      supervisor(Nick.Agent, []),
      supervisor(Channel.Supervisor, []),
      supervisor(Network.Raw.TCP.Supervisor, []),
      supervisor(Network.Raw.SSL.Supervisor, []),
      supervisor(:cowboy, cowboy_args, function: :start_http)
    ]

    opts = [strategy: :one_for_one, name: XonnectGateway.Supervisor]
    Supervisor.start_link(children, opts)
  end
end

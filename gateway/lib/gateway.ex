defmodule XonnectGateway do
  use Application

  def start(_type, _args) do
    import Supervisor.Spec, warn: false

    cowboy = Application.get_env(:gateway, :cowboy)
    domain = cowboy[:domain]
    port = cowboy[:port]

    websocket = :sockjs_handler.init_state("/api/v1", Handler.Socket, [], [])

    dispatch = :cowboy_router.compile([
      {domain, [
        {"/assets/[...]", :cowboy_static, {
          :priv_dir, :gateway, "assets", [{:mimetypes, :cow_mimetypes, :all}]
        }},
        {"/api/v1/websocket", :sockjs_cowboy_handler, websocket}
      ]}
    ])

    cowboy_args = [:http, 8,
      [{:port, port}],
      [{:env, [{:dispatch, dispatch}]}]
    ]

    children = [
      supervisor(Nick.Agent, []),
      supervisor(:cowboy, cowboy_args, function: :start_http)
    ]

    opts = [strategy: :one_for_one, name: XonnectGateway.Supervisor]
    Supervisor.start_link(children, opts)
  end
end

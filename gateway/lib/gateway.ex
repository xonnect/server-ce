defmodule XonnectGateway do
  use Application

  def start(_type, _args) do
    import Supervisor.Spec, warn: false

    cowboy = Application.get_env(:gateway, :cowboy)
    domain = cowboy[:domain]
    port = cowboy[:port]

    json_interface = :sockjs_handler.init_state("/jsonapi/v1", Handler.Socket, :json_interface, [])
    bson_interface = :sockjs_handler.init_state("/bsonapi/v1", Handler.Socket, :bson_interface, [])

    dispatch = :cowboy_router.compile([
      {domain, [
        {"/assets/[...]", :cowboy_static, {
          :priv_dir, :gateway, "assets", [{:mimetypes, :cow_mimetypes, :all}]
        }},
        {"/jsonapi/v1/websocket", :sockjs_cowboy_handler, json_interface},
        {"/bsonapi/v1/websocket", :sockjs_cowboy_handler, bson_interface}
      ]}
    ])

    cowboy_args = [:http, 8,
      [{:port, port}],
      [{:env, [{:dispatch, dispatch}]}]
    ]

    children = [
      supervisor(:cowboy, cowboy_args, function: :start_http)
    ]

    opts = [strategy: :one_for_one, name: XonnectGateway.Supervisor]
    Supervisor.start_link(children, opts)
  end
end

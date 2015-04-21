use Mix.Config

config :gateway, :cowboy,
  domain: "localhost",
  port: 60081,
  listener_num: 32

config :gateway, :tcp_interface,
  port: 50080,
  listener_num: 16

config :gateway, :ssl_interface,
  port: 50443,
  listener_num: 16

config :lager, :handlers,
  lager_console_backend: :debug,
  lager_file_backend: [file: 'log/info.log', level: :info, size: 20971520, date: '$D0', count: 10],
  lager_file_backend: [file: 'log/error.log', level: :error, size: 20971520, date: '$D0', count: 10]

config :exlager,
  level: :debug,
  truncation_size: 8192

config :gateway, :nick_worker_pool,
  size: 8,
  max_overflow: 12

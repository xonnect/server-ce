defmodule XonnectGateway.Mixfile do
  use Mix.Project

  def project do
    [app: :gateway,
     version: "0.0.1",
     elixir: "~> 1.0",
     build_embedded: Mix.env == :prod,
     start_permanent: Mix.env == :prod,
     deps: deps]
  end

  # Type `mix help compile.app` for more information
  def application do
    [applications: [:cowboy, :jsx, :sockjs, :exlager, :amnesia, :socket],
     mod: {XonnectGateway, []}]
  end

  # Type `mix help deps` for more examples and options
  defp deps do
    [{:cowboy, git: "git://github.com/ninenines/cowboy.git", ref: "b57f94661f5fd186f55eb0fead49849e0b1399d1", override: true},
     {:jsx, git: "git://github.com/talentdeficit/jsx.git"},
     {:sockjs, git: "git://github.com/xhs/sockjs-erlang.git"},
     {:exlager, git: "git://github.com/khia/exlager.git"},
     {:amnesia, git: "git://github.com/meh/amnesia.git"},
     {:poolboy, git: "git://github.com/devinus/poolboy.git", override: true},
     {:uuid, git: "git://github.com/okeuday/uuid.git"},
     {:bson, git: "git://github.com/checkiz/elixir-bson.git"},
     {:socket, git: "git://github.com/meh/elixir-socket.git"}]
  end
end

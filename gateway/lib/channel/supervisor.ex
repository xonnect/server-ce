defmodule Channel.Supervisor do
  use Supervisor

  # Supervisor api
  def start_child(identifier) do
    Supervisor.start_child __MODULE__, [identifier]
  end

  def start_link() do
    Supervisor.start_link __MODULE__, [], name: __MODULE__
  end

  # Supervisor callback
  def init([]) do
    children = [
      worker(Channel.Agent, [], restart: :temporary, shutdown: :brutal_kill)
    ]
    supervise children, strategy: :simple_one_for_one, max_restarts: 0, max_seconds: 1
  end
end

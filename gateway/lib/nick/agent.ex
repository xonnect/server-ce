defmodule Nick.Agent do
  use Supervisor
  @pool :nick_worker_pool

  # Supervisor callback
  def init([]) do
    pool_specs = Application.get_env(:gateway, @pool)
    worker = Nick.Worker
    children = [
      :poolboy.child_spec(@pool, [name: {:local, @pool}, worker_module: worker] ++ pool_specs, [])
    ]
    supervise children, strategy: :one_for_one, max_restarts: 10, max_seconds: 10
  end

  # api
  def start_link() do
    Supervisor.start_link __MODULE__, [], [name: __MODULE__]
  end

  def register() do
    :poolboy.transaction(@pool, fn(worker) -> GenServer.call(worker, :register) end)
  end

  def register(nick) do
    :poolboy.transaction(@pool, fn(worker) -> GenServer.call(worker, {:register, nick}) end)
  end
end

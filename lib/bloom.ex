defmodule Bloom do
  use Application

  def start(_type, _args) do
    import Supervisor.Spec, warn: false

    children = [
      worker(Task, [Bloom.Bot, :run, []])
    ]

    Supervisor.start_link(children, max_restarts: 30, strategy: :one_for_one, name: Bloom.Supervisor)
  end
end

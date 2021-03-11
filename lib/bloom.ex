defmodule Bloom do
  use Application

  def start(_type, _args) do
    import Supervisor.Spec, warn: false

    children = [
      %{
        id: Bloom.Bot.Task,
        start: {Task, :start_link, [Bloom.Bot, :run, []]}
      },
      %{
        id: Bloom.External.Eth.User,
        start: {Bloom.External.Eth.User, :start_link, []}
      },
      %{
        id: Bloom.External.LastFM.User,
        start: {Bloom.External.LastFM.User, :start_link, []}
      }
    ]

    {:ok, _pid} =
      Supervisor.start_link(children,
        max_restarts: 30,
        strategy: :one_for_one,
        name: Bloom.Supervisor
      )
  end
end

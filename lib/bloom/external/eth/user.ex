defmodule Bloom.External.Eth.User do
  use Agent

  @initial %{
  }

  def start_link do
    Agent.start_link(fn -> @initial end, name: __MODULE__)
  end

  def addresses(id) do
    Agent.get(__MODULE__, &Map.fetch(&1, id))
  end
end

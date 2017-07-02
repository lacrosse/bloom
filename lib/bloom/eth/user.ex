defmodule Bloom.Eth.User do
  @initial %{
  }

  def start_link do
    Agent.start_link(fn -> @initial end, name: __MODULE__)
  end

  def addresses(id) do
    Agent.get(__MODULE__, &Map.get(&1, id))
  end
end

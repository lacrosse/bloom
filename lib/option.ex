defmodule Option do
  def lpush(opt, l), do: Enum.reduce(l, opt, &push(&2, &1))

  def push({:ok, x}, x), do: :error
  def push(:error, _), do: :error
  def push({:ok, x}, _), do: {:ok, x}

  def map({:ok, x}, f), do: {:ok, f.(x)}
  def map(:error, _), do: :error

  def flat_map({:ok, x}, f), do: f.(x)
  def flat_map(:error, _), do: :error

  def unwrap(opt, bottom \\ nil)
  def unwrap({:ok, x}, _), do: x
  def unwrap(:error, bottom), do: bottom

  def to_either({:ok, _} = opt, _), do: opt
  def to_either(:error, msg), do: {:error, msg}
end

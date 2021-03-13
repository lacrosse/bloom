defmodule Either do
  @type t(ok, error) :: {:ok, ok} | {:error, error}
  @type t(a) :: t(a, a)
  @type t() :: t(any)

  @spec unwrap(t(a, b)) :: a | b when a: any, b: any
  def unwrap({:ok, v}), do: v
  def unwrap({:error, v}), do: v

  def left_map({:ok, v}, f), do: {:ok, f.(v)}
  def left_map(ei, _), do: ei

  def right_map({:error, v}, f), do: {:error, f.(v)}
  def right_map(ei, _), do: ei
end

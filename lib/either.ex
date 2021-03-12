defmodule Either do
  @type t(ok, error) :: {:ok, ok} | {:error, error}
  @type t(a) :: t(a, a)
  @type t() :: t(any)

  @spec unwrap(t(a, b)) :: a | b when a: any, b: any
  def unwrap({:ok, v}), do: v
  def unwrap({:error, v}), do: v
end

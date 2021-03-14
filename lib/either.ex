defmodule Either do
  @type t(ok, error) :: {:ok, ok} | {:error, error}
  @type t(a) :: t(a, a)
  @type t() :: t(any)

  @spec unwrap(t(a, b)) :: a | b
        when a: any, b: any
  def unwrap({:ok, v}), do: v
  def unwrap({:error, v}), do: v

  @spec map_ok(t(a, b), (a -> c)) :: t(c, b)
        when a: any, b: any, c: any
  def map_ok({:ok, v}, f), do: {:ok, f.(v)}
  def map_ok(ei, _), do: ei

  @spec map_error(t(a, b), (b -> c)) :: t(a, c)
        when a: any, b: any, c: any
  def map_error({:error, v}, f), do: {:error, f.(v)}
  def map_error(ei, _), do: ei

  @spec flat_map(t(a, b), (a -> t(c, d)), (c -> e), (d -> b)) :: t(e, b)
        when a: any, b: any, c: any, d: any, e: any
  def flat_map({:ok, v}, f, left_f, right_f), do: f.(v) |> map_ok(left_f) |> map_error(right_f)
  def flat_map(ei, _, _, _), do: ei
end

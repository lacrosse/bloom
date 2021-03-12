defmodule Bloom.External.Utils do
  defmacro with_decode(service, request) do
    quote do
      with {:fetch, {:ok, %HTTPoison.Response{body: raw_data}}} <- {:fetch, unquote(request)},
           {:decode, {:ok, data}} = {:decode, Poison.decode(raw_data)} do
        {:ok, data}
      else
        {:fetch, {:error, _}} -> {:error, "Couldn't get a response from #{unquote(service)}."}
        {:decode, {:error, _}} -> {:error, "Got a malformed response from #{unquote(service)}."}
      end
    end
  end
end

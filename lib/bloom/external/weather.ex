defmodule Bloom.External.Weather do
  require Bloom.External.Utils
  alias Bloom.External.Utils

  @darksky_secret_key Application.fetch_env!(:bloom, :darksky_secret_key)
  @opencage_api_key Application.fetch_env!(:bloom, :opencage_api_key)

  @spec describe(String.t()) :: Either.t(String.t())
  def describe(query), do: forecast(query)

  defp wrap_data(%{"error" => error}), do: {:error, error}
  defp wrap_data(data), do: {:ok, data}

  defp forecast(query) do
    with {:geocode, {:ok, coords_string}} <- {:geocode, geocode_query(query)},
         excluded = Enum.join(~w[minutely hourly daily], ","),
         url_query = URI.encode_query(%{exclude: excluded, lang: :ru, units: :si}),
         url =
           "https://api.darksky.net/forecast/#{@darksky_secret_key}/#{coords_string}/?#{url_query}",
         {:darksky_fetch, {:ok, data}} <-
           {:darksky_fetch, Utils.with_decode("darksky.net", HTTPoison.get(url))},
         {:darksky, {:ok, result}} <- {:darksky, wrap_data(data)},
         {:wellformed, {:ok, currently}} <- {:wellformed, Map.fetch(result, "currently")},
         celsius = "#{currently["temperature"]}°C" do
      summary =
        currently
        |> Map.fetch("summary")
        |> Option.lpush([nil, ""])
        |> Option.map(&String.downcase/1)
        |> Option.unwrap()
        |> List.wrap()

      temperature = ([celsius] ++ summary) |> Enum.join(", ")

      alerts_block =
        result
        |> Map.fetch("alerts")
        |> Option.push(nil)
        |> Option.map(
          &(&1
            |> Enum.map(fn %{"title" => title, "uri" => url} -> "[#{title}](#{url})" end)
            |> Enum.join("\n"))
        )
        |> Option.unwrap()
        |> List.wrap()

      {:ok,
       ([temperature] ++ alerts_block)
       |> Enum.join("\n\n")}
    else
      {:geocode, {:error, error}} -> {:error, error}
      {:darksky_fetch, {:error, error}} -> {:error, error}
      {:darksky, {:error, _}} -> {:error, "darksky.net error"}
      {:wellformed, :error} -> {:error, "darksky.net response is not well-formed"}
    end
  end

  # TODO
  defp geocode_query(query) do
    with url_query = URI.encode_query(%{key: @opencage_api_key, q: URI.encode(query), limit: 1}),
         url = "https://api.opencagedata.com/geocode/v1/json?#{url_query}",
         {:ok, data} <- Utils.with_decode("opencagedata.com", HTTPoison.get(url)),
         {:ok, results} <- data |> Map.fetch("results"),
         [result] = results,
         {:ok, geometry} <- result |> Map.fetch("geometry"),
         {:ok, lat} <- geometry |> Map.fetch("lat"),
         {:ok, lng} <- geometry |> Map.fetch("lng") do
      {:ok, "#{lat},#{lng}"}
    end
  end
end

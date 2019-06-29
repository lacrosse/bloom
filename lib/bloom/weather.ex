defmodule Bloom.Weather do
  @darksky_secret_key Application.fetch_env!(:bloom, :darksky_secret_key)
  @opencage_api_key Application.fetch_env!(:bloom, :opencage_api_key)

  def describe(query) do
    forecast(query)
  end

  defp forecast(query) do
    case query |> geocode_query() do
      :error ->
        "ошибка, ошибка"

      {:ok, coords_string} ->
        url_query =
          %{
            exclude:
              ~w[minutely hourly daily alerts flags]
              |> Enum.join(","),
            lang: :ru,
            units: :si
          }
          |> URI.encode_query()

        url =
          "https://api.darksky.net/forecast/#{@darksky_secret_key}/#{coords_string}/?#{url_query}"

        case HTTPoison.get(url) do
          {:ok, %HTTPoison.Response{body: body}} ->
            case Poison.decode(body) do
              {:ok, %{"error" => error}} ->
                error

              {:ok, parsed} ->
                currently = parsed["currently"]
                temperature = currently["temperature"]
                temperature_string = "#{temperature}°C"

                case currently["summary"] do
                  nil ->
                    temperature_string

                  summary ->
                    normalized_summary = summary |> String.downcase()
                    "#{temperature_string}, #{normalized_summary}"
                end
            end

          {:error, _error} ->
            "сорян(("
        end
    end
  end

  # TODO
  defp geocode_query(query) do
    escaped_query = query |> URI.encode()

    url_query =
      %{
        q: escaped_query,
        key: @opencage_api_key,
        limit: 1
      }
      |> URI.encode_query()

    url = "https://api.opencagedata.com/geocode/v1/json?#{url_query}"

    case HTTPoison.get(url) do
      {:ok, %HTTPoison.Response{body: body}} ->
        case Poison.decode(body) do
          {:ok, parsed} ->
            case parsed["results"] do
              [] ->
                :error

              [%{"geometry" => %{"lat" => lat, "lng" => lng}}] ->
                latlng = "#{lat},#{lng}"
                {:ok, latlng}
            end
        end
    end
  end
end

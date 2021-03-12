defmodule Bloom.External.LastFM do
  require Bloom.External.Utils

  @endpoint "https://ws.audioscrobbler.com/2.0"
  @api_key Application.fetch_env!(:bloom, :lastfm_api_key)

  defmacrop decode(request) do
    quote do
      with {:lastfm_fetch, {:ok, raw_data}} <-
             {:lastfm_fetch, Bloom.External.Utils.with_decode("last.fm", unquote(request))},
           {:lastfm, {:ok, data}} <- {:lastfm, wrap_data(raw_data)} do
        {:ok, data}
      else
        {:lastfm_fetch, {:error, error}} -> {:error, error}
        {:lastfm, {:error, error}} -> {:error, "last.fm said: " <> error}
      end
    end
  end

  @spec get_recent(String.t()) :: Either.t(String.t())
  def get_recent(username) do
    with {:decode, {:ok, data}} <- {:decode, decode(request_getrecenttracks(username))},
         {:wf, {:ok, recenttracks}} <- {:wf, data |> Map.fetch("recenttracks")},
         {:wf, {:ok, tracks}} <- {:wf, recenttracks |> Map.fetch("track")},
         {:wf, [track | _]} <- {:wf, tracks},
         {:wf, {:ok, artist}} <- {:wf, track |> Map.fetch("artist")},
         {:wf, {:ok, artist_name}} <- {:wf, artist |> Map.fetch("#text")},
         {:wf, {:ok, title}} <- {:wf, track |> Map.fetch("name")} do
      emoji =
        track
        |> Map.fetch("@attr")
        |> Option.flat_map(&Map.fetch(&1, "nowplaying"))
        |> Option.map(&(&1 == "true"))
        |> Option.unwrap(false)
        |> (fn x -> if x, do: "🎧", else: "🎶" end).()

      {:ok, "#{emoji} #{artist_name} – #{title}"}
    else
      {:decode, err} -> err
      {:wf, _} -> {:error, "Response is not well-formed"}
    end
  end

  @spec get_artist(integer, any) :: Either.t(String.t())
  def get_artist(telegram_user_id, artist) do
    with {:ok, username} <- lastfm_username(telegram_user_id) do
      with {:decode, {:ok, data}} <- {:decode, decode(request_artist_getinfo(username, artist))},
           {:wf, {:ok, artist}} <- {:wf, data |> Map.fetch("artist")},
           {:wf, {:ok, artist_name}} <- {:wf, artist |> Map.fetch("name")},
           {:wf, {:ok, stats}} <- {:wf, artist |> Map.fetch("stats")},
           {:wf, {:ok, count_str}} <- {:wf, stats |> Map.fetch("userplaycount")},
           count = count_str |> String.to_integer() do
        {:ok,
         "#{username} scrobbled #{artist_name} #{count} #{pluralize("time", count)}" <>
           case count do
             0 -> " ¯\\_(ツ)_/¯"
             _ -> ""
           end}
      else
        {:decode, err} -> err
        {:wf, _} -> {:error, "Response is not well-formed"}
      end
    end
  end

  @spec describe(integer) :: Either.t(String.t())
  def describe(telegram_user_id) do
    with {:ok, username} <- lastfm_username(telegram_user_id),
         do: get_recent(username)
  end

  defp pluralize(noun, n) when abs(n) == 1, do: noun
  defp pluralize(noun, _), do: noun <> "s"

  defp wrap_data(%{"error" => _, "message" => message}), do: {:error, message}
  defp wrap_data(res), do: {:ok, res}

  defp lastfm_username(telegram_user_id) do
    Bloom.External.LastFM.User.username(telegram_user_id)
    |> Option.to_either("I don't know you.")
  end

  defp request_getrecenttracks(username),
    do: request("user.getrecenttracks", %{user: username, limit: 1})

  defp request_artist_getinfo(username, artist),
    do: request("artist.getinfo", %{artist: artist, username: username})

  defp request(method, args) do
    query =
      %{
        api_key: @api_key,
        method: method,
        format: :json
      }
      |> Map.merge(args)
      |> URI.encode_query()

    HTTPoison.get("#{@endpoint}/?#{query}")
  end
end

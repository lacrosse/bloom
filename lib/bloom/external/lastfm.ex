defmodule Bloom.External.LastFM do
  require Bloom.External.Utils
  alias Bloom.{Repo, User}

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

  @spec get_recent(String.t()) :: Either.t(Bloom.Bot.resolution())
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
        |> Maybe.flat_map(&Map.fetch(&1, "nowplaying"))
        |> Maybe.map(&(&1 == "true"))
        |> Maybe.unwrap(false)
        |> (fn x -> if x, do: "🎧", else: "🎶" end).()

      {:ok, "#{emoji} #{artist_name} – #{title}"}
    else
      {:decode, err} -> err
      {:wf, _} -> {:error, "Response is not well-formed"}
    end
    |> Either.map_ok(&{&1, false})
    |> Either.map_error(&{&1, false})
  end

  @spec get_artist(integer, any) :: Either.t(Bloom.Bot.resolution())
  def get_artist(telegram_user_id, artist) do
    with {:ok, username} <- lastfm_username(telegram_user_id) do
      with {:decode, {:ok, data}} <-
             {:decode, decode(request_artist_getinfo(username, artist))},
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
      |> Either.map_ok(&{&1, false})
      |> Either.map_error(&{&1, false})
    end
  end

  @spec describe(integer) :: Either.t(Bloom.Bot.resolution())
  def describe(telegram_user_id) do
    with {:ok, username} <- lastfm_username(telegram_user_id),
         do: get_recent(username)
  end

  defp pluralize(noun, n) when abs(n) == 1, do: noun
  defp pluralize(noun, _), do: noun <> "s"

  defp wrap_data(%{"error" => _, "message" => message}), do: {:error, message}
  defp wrap_data(res), do: {:ok, res}

  def lastfm_username(telegram_user_id) do
    Repo.get(User, telegram_user_id)
    |> Maybe.wrap()
    |> Maybe.map(& &1.lastfm_username)
    |> Maybe.push("")
    |> Maybe.to_either("I don't know you.")
  end

  def memorize(telegram_user_id, username) do
    case Repo.get(User, telegram_user_id) do
      nil -> %User{id: telegram_user_id}
      user -> user
    end
    |> User.changeset(%{lastfm_username: username})
    |> Repo.insert_or_update()
    |> Either.map_ok(fn _ -> "Nice to meet you." end)
    |> Either.map_error(fn _ -> "Something went wrong" end)
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

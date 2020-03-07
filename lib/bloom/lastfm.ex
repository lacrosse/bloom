defmodule Bloom.LastFM do
  @endpoint "https://ws.audioscrobbler.com/2.0"
  @api_key Application.fetch_env!(:bloom, :lastfm_api_key)

  def describe(telegram_user_id) do
    case Bloom.LastFM.User.username(telegram_user_id) do
      nil ->
        IO.inspect("Telegram user #{telegram_user_id} tried to use last.fm")
        "это кто"

      username ->
        get_recent(username)
    end
  end

  def get_recent(username) do
    case request_getrecenttracks(username) do
      {:ok, %HTTPoison.Response{body: body}} ->
        with {:ok, parsed} = Poison.decode(body),
             tracks <- parsed["recenttracks"]["track"],
             track = List.first(tracks),
             artist <- track["artist"]["#text"],
             name <- track["name"] do
          now_playing =
            case Map.get(track, "@attr") do
              nil -> false
              attr -> Map.get(attr, "nowplaying") == "true"
            end

          emoji =
            if now_playing do
              "🎧"
            else
              "🎶"
            end

          "#{emoji} #{artist} – #{name}"
        end

      {:error, _error} ->
        "сорян(("
    end
  end

  def get_artist(username, artist) do
    case(request_artist_getinfo(username, artist)) do
      {:ok, %HTTPoison.Response{body: body}} ->
        with {:ok, parsed} = Poison.decode(body),
             stats <- parsed["artist"]["stats"],
             count = stats["userplaycount"] do
          "#{username} scrobbled #{artist} #{count} times"
        end

      {:error, _error} ->
        "::("
    end
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

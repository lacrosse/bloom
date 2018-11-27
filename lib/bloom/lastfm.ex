defmodule Bloom.LastFM do
  @api_key Application.fetch_env!(:bloom, :lastfm_api_key)
  @users %{
  }

  def describe(telegram_user_id) do
    case Map.get(@users, telegram_user_id) do
      nil ->
        IO.inspect "Telegram user #{telegram_user_id} tried to use last.fm"
        "это кто"
      username ->
        get_recent(username)
    end
  end

  def get_recent(username) do
    case HTTPoison.get("https://ws.audioscrobbler.com/2.0/?method=user.getrecenttracks&user=#{username}&api_key=#{@api_key}&limit=1&format=json") do
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
      {:error, error} ->
        :error
        "сорян(("
    end
  end
end

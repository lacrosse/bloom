defmodule Bloom.LastFM do
  @endpoint "https://ws.audioscrobbler.com/2.0"
  @api_key Application.fetch_env!(:bloom, :lastfm_api_key)
  @users %{
  }

  def describe(telegram_user_id) do
    case Map.get(@users, telegram_user_id) do
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

  defp request_getrecenttracks(username),
    do: request("user.getrecenttracks", %{user: username, limit: 1})

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

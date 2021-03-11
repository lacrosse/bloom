defmodule Bloom.Bot.QueryResolver do
  @spec resolve(integer, String.t()) :: String.t()
  def resolve(telegram_user_id, full_query) do
    case full_query do
      "weather " <> query ->
        Bloom.External.Weather.describe(query)

      "eth me" ->
        Bloom.External.Eth.describe("me", telegram_user_id)

      "eth " <> eth_entity ->
        Bloom.External.Eth.describe(eth_entity)

      "lastfm" ->
        Bloom.External.LastFM.describe(telegram_user_id)

      "lastfm np " <> username ->
        Bloom.External.LastFM.get_recent(username)

      "lastfm ident " <> username ->
        Bloom.External.LastFM.User.memorize(telegram_user_id, String.trim(username))
        "ok"

      "lastfm artist " <> artist ->
        Bloom.External.LastFM.get_artist(telegram_user_id, artist)

      _ ->
        "nah"
    end
  end
end

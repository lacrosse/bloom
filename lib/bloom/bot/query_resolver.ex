defmodule Bloom.Bot.QueryResolver do
  alias Bloom.External.{Weather, Eth, LastFM}

  @spec resolve(integer, String.t()) :: String.t()
  def resolve(telegram_user_id, full_query) do
    case full_query do
      "weather " <> query ->
        Weather.describe(query)

      "eth" ->
        Eth.net_worth(telegram_user_id)

      "eth " <> eth_entity ->
        Eth.describe(eth_entity)

      "lastfm" ->
        LastFM.describe(telegram_user_id)

      "lastfm np " <> username ->
        LastFM.get_recent(username)

      "lastfm artist " <> artist ->
        LastFM.get_artist(telegram_user_id, artist)

      "lastfm ident " <> username ->
        LastFM.memorize(telegram_user_id, String.trim(username))

      _ ->
        {:error, "I'm afraid I can't let you do that."}
    end
    |> Either.unwrap()
  end
end

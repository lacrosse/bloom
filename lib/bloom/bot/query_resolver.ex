defmodule Bloom.Bot.QueryResolver do
  alias Bloom.EthAddress
  alias Bloom.External.{Weather, Eth, LastFM}

  @spec resolve(Nadia.Model.Message.t(), String.t()) :: Bloom.Bot.resolution()
  def resolve(message, full_query, opts \\ []) do
    telegram_user_id = message.from.id

    case full_query do
      "weather " <> query ->
        Weather.describe(query)

      "eth" ->
        Eth.net_worth(telegram_user_id)

      "eth list" ->
        EthAddress.all_of_user_reply(telegram_user_id)

      "eth list add " <> hex ->
        EthAddress.add_to_user_reply(telegram_user_id, hex)

      "eth list rm " <> hex ->
        EthAddress.rm_from_user_reply(telegram_user_id, hex)

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
        {:error, {nil, false}}
    end
    |> Either.unwrap()
  end
end

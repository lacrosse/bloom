defmodule Bloom.Bot.InlineQueryHandler do
  alias Nadia.Model.{InlineQuery, InlineQueryResult.Article, InputMessageContent.Text}

  @spec handle(Nadia.Model.InlineQuery.t()) :: :ok
  def handle(%InlineQuery{from: user, query: query} = iq) do
    iq |> IO.inspect()

    case query do
      "lastfm" ->
        with {:ok, text} <- Bloom.External.LastFM.describe(user.id) do
          content = %Text{
            message_text: text,
            parse_mode: "Markdown"
          }

          result = %Article{
            id: "93",
            title: text,
            input_message_content: content
          }

          results = [result]

          Nadia.answer_inline_query(iq.id, results,
            is_personal: true,
            next_offset: "",
            cache_time: 15
          )

          :ok
        end

      _ ->
        :ok
    end
  end
end

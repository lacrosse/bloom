defmodule Bloom.Bot.InlineQueryHandler do
  alias Nadia.Model

  def handle(%Model.InlineQuery{from: user, query: query} = iq) do
    iq |> IO.inspect()

    case query do
      "lastfm" ->
        text = Bloom.External.LastFM.describe(user.id)

        result = %Model.InlineQueryResult.Article{
          id: "93",
          title: text,
          input_message_content: %Model.InputMessageContent.Text{
            message_text: text,
            parse_mode: "Markdown"
          }
        }

        Nadia.answer_inline_query(iq.id, [result],
          is_personal: true,
          next_offset: "",
          cache_time: 15
        )

        :ok

      _ ->
        :ok
    end
  end
end

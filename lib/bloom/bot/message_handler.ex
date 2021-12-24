defmodule Bloom.Bot.MessageHandler do
  alias Nadia.Model.Message

  @reset :reset
  @double_echo Application.fetch_env!(:bloom, :double_echo)

  @spec handle(Message.t(), Bloom.Bot.history()) ::
          {Bloom.Bot.opt_message(), Bloom.Bot.history()}
  def handle(%Message{text: text, reply_to_message: reply_to_message} = message, history) do
    case text do
      nil ->
        {:none, history}

      _ ->
        reply_to_id = message.message_id

        {reply_txt, enable_markdown} =
          case text do
            "/" <> slash_query ->
              Bloom.Bot.QueryResolver.resolve(message, slash_query, reply_to: reply_to_message)

            _ ->
              {cond do
                 text == Map.get(history, message.chat.id, @reset) && @double_echo -> text
                 true -> nil
               end, false}
          end

        {reply_msg, new_subhistory} =
          case reply_txt do
            nil ->
              {:none, text}

            _ ->
              result =
                Nadia.send_message(message.chat.id, reply_txt,
                  parse_mode: if(enable_markdown, do: "Markdown", else: nil),
                  disable_web_page_preview: "True",
                  reply_to_message_id: reply_to_id
                )

              case result do
                {:ok, _} ->
                  {result, @reset}

                _ ->
                  {reply_txt, result} |> IO.inspect()
                  {:none, text}
              end
          end

        {reply_msg, Map.put(history, message.chat.id, new_subhistory)}
    end
  end
end

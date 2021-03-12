defmodule Bloom.Bot.MessageHandler do
  alias Nadia.Model.Message

  @reset :reset
  @double_echo Application.fetch_env!(:bloom, :double_echo)

  @spec handle(Message.t(), Bloom.Bot.history()) ::
          {Bloom.Bot.opt_message(), Bloom.Bot.history()}
  def handle(%Message{} = message, history) do
    case message.text do
      nil ->
        {:none, history}

      _ ->
        reply_txt =
          case message.text do
            "/" <> slash_query ->
              Bloom.Bot.QueryResolver.resolve(message.from.id, slash_query)

            _ ->
              cond do
                message.text == Map.get(history, message.chat.id, @reset) && @double_echo ->
                  message.text

                true ->
                  nil
              end
          end

        {reply_msg, new_subhistory} =
          with {:reply_empty, false} <- {:reply_empty, is_nil(reply_txt)},
               {:telegram, {:ok, reply_msg}} <-
                 {:telegram,
                  Nadia.send_message(message.chat.id, reply_txt,
                    parse_mode: "Markdown",
                    disable_web_page_preview: "True",
                    reply_to_message_id: message.message_id
                  )} do
            {{:ok, reply_msg}, @reset}
          else
            _ -> {:none, message.text}
          end

        {reply_msg, Map.put(history, message.chat.id, new_subhistory)}
    end
  end
end

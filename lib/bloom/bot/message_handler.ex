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
        {reply_txt, reply_to_id} =
          case text do
            "/" <> slash_query ->
              {Bloom.Bot.QueryResolver.resolve(message.from.id, slash_query,
                 reply_to: reply_to_message
               ), message.message_id}

            _ ->
              {cond do
                 text == Map.get(history, message.chat.id, @reset) && @double_echo ->
                   text

                 true ->
                   nil
               end, message.message_id}
          end

        {reply_msg, new_subhistory} =
          with {:reply_empty, false} <- {:reply_empty, is_nil(reply_txt)},
               {:telegram, {:ok, reply_msg}} <-
                 {:telegram,
                  Nadia.send_message(message.chat.id, reply_txt,
                    parse_mode: "Markdown",
                    disable_web_page_preview: "True",
                    reply_to_message_id: reply_to_id
                  )} do
            {{:ok, reply_msg}, @reset}
          else
            _ -> {:none, text}
          end

        {reply_msg, Map.put(history, message.chat.id, new_subhistory)}
    end
  end
end

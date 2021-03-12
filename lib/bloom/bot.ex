defmodule Bloom.Bot do
  alias Nadia.Model.{User, Update, Message, InlineQuery}

  @type history :: %{integer => :reset | String.t()}
  @type opt_message :: {:ok, Message.t()} | :none

  def run do
    :ok = flush()
    poll()
  end

  defp flush(offset \\ nil) do
    case Application.fetch_env!(:bloom, :flush) do
      true ->
        case Nadia.get_updates(offset: offset) do
          {:ok, []} ->
            :ok

          {:ok, updates} ->
            Enum.each(updates, &echo_locally(&1.message))
            flush(List.last(updates).update_id + 1)

          {:error, error} ->
            IO.inspect(error)
            flush(offset)
        end

      false ->
        :ok
    end
  end

  defp poll(offset \\ nil, history \\ %{}) do
    case Nadia.get_updates(offset: offset, limit: 1) do
      {:ok, []} ->
        poll(offset, history)

      {:ok, updates} ->
        {new_offset, new_history} = Enum.reduce(updates, history, &ack_and_reply/2)
        poll(new_offset, new_history)

      {:error, error} ->
        IO.inspect(error)
        :error
    end
  end

  defp echo_locally(message), do: message |> describe_message() |> IO.puts()

  defp ack_and_reply(%Update{update_id: update_id} = upd, history) do
    new_history =
      case upd do
        %Update{message: %Message{} = msg} when not is_nil(msg) ->
          echo_locally(msg)
          {reply_msg, new_history} = Bloom.Bot.MessageHandler.handle(msg, history)

          case reply_msg do
            {:ok, reply_msg} -> echo_locally(reply_msg)
            :none -> "No reply"
          end

          new_history

        %Update{inline_query: %InlineQuery{} = iq} when not is_nil(iq) ->
          Bloom.Bot.InlineQueryHandler.handle(iq)
          history

        _ ->
          IO.puts("skipped update")
          history
      end

    {update_id + 1, new_history}
  end

  defp describe_message(%Message{} = message) do
    chat = describe_chat(message.chat)
    date = message.date |> DateTime.from_unix!() |> DateTime.to_iso8601()
    user = describe_user(message.from)

    "{#{chat}} [#{date}] <#{user}>" <>
      if(length(message.photo) > 0, do: " [photo]", else: "") <>
      if(message.text, do: " #{message.text}", else: "")
  end

  defp describe_message(_) do
    "# Invalid message"
  end

  defp describe_chat(chat) do
    "#{chat.type}#{if chat.title, do: "##{chat.title}"}"
  end

  defp describe_user(%User{first_name: f, last_name: l, username: u, id: id}) do
    names =
      [f, l]
      |> Enum.map(&to_string/1)
      |> Enum.filter(&(String.length(&1) > 0))

    case {names, u} do
      {[], nil} ->
        "id#{id}"

      {[], _} ->
        "@#{u}"

      {_, nil} ->
        Enum.join(names, " ")

      {_, _} ->
        "#{Enum.join(names, " ")} (@#{u})"
    end
  end
end

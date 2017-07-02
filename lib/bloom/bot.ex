defmodule Bloom.Bot do
  @flush Application.fetch_env!(:bloom, :flush)
  @reset :reset
  @double_echo Application.fetch_env!(:bloom, :double_echo)

  def run do
    if @flush, do: :ok = flush()
    poll()
  end

  defp flush(offset \\ nil) do
    case Nadia.get_updates(offset: offset) do
      {:ok, []} ->
        :ok
      {:ok, updates} ->
        updates |> Enum.each(&ack(&1.message))
        flush(List.last(updates).update_id + 1)
    end
  end

  defp poll(offset \\ nil, history \\ %{}) do
    case Nadia.get_updates(offset: offset, limit: 1, timeout: 20) do
      {:ok, []} ->
        poll(offset, history)
      {:ok, updates} ->
        {new_offset, new_history} = many_ack_and_reply(updates, history)
        poll(new_offset, new_history)
    end
  end

  defp many_ack_and_reply(updates, previous) do
    Enum.reduce(updates, {nil, previous}, fn update, {_offset, acc_previous} ->
      ack_and_reply(update, acc_previous)
    end)
  end

  defp ack(message), do: message |> describe_message() |> IO.puts()

  defp ack_and_reply(%Nadia.Model.Update{update_id: update_id, message: %Nadia.Model.Message{chat: chat} = message}, history) do
    ack(message)

    new_subhistory =
      cond do
        message.text |> String.starts_with?("/eth ") ->
          <<"/eth ", eth_entity::binary>> = message.text
          reply =
            case eth_entity do
              "me" ->
                Bloom.Eth.describe("me", message.from.id)
              _ ->
                Bloom.Eth.describe(eth_entity)
            end
          {:ok, my_message} = Nadia.send_message chat.id, reply
          ack(my_message)
          @reset
        message.text == Map.get(history, chat.id, @reset) && @double_echo ->
          {:ok, my_message} = Nadia.send_message chat.id, message.text
          ack(my_message)
          @reset
        true ->
          message.text
      end

    with new_history = Map.put(history, chat.id, new_subhistory),
         do: {update_id + 1, new_history}
  end
  defp ack_and_reply(%Nadia.Model.Update{update_id: update_id, message: message}, history) when is_nil(message) do
    ack(message)
    {update_id + 1, history}
  end

  defp describe_message(%Nadia.Model.Message{chat: chat, date: date, from: from, text: text, photo: photo}) do
    "{#{describe_chat(chat)}} " <>
    "[#{DateTime.from_unix!(date) |> DateTime.to_iso8601()}] " <>
    "<#{describe_user(from)}>" <>
    "#{if length(photo) > 0, do: " [photo]"}" <>
    "#{if text, do: " #{text}"}"
  end
  defp describe_message(_) do
    "# Invalid message"
  end

  defp describe_chat(chat) do
    "#{chat.type}#{if chat.title, do: "##{chat.title}"}"
  end

  defp describe_user(%Nadia.Model.User{first_name: f, last_name: l, username: u, id: id}) do
    human_name =
      [f, l]
      |> Enum.map(&to_string/1)
      |> Enum.filter(&String.length(&1) > 0)
      |> Enum.join(" ")

    handle = if u, do: "@#{u}"

    cond do
      String.length(human_name) > 0 ->
        "#{human_name}#{if handle, do: " (#{handle})"}"
      handle ->
        handle
      true ->
        "id#{id}"
    end
  end
end

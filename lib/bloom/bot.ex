defmodule Bloom.Bot do
  @double_echo Application.fetch_env!(:bloom, :double_echo)
  @reset :reset

  def run do
    :ok = flush
    poll
  end

  defp flush(offset \\ nil) do
    case Nadia.get_updates(offset: offset) do
      {:ok, []} -> :ok
      {:ok, updates} ->
        flush(List.last(updates).update_id + 1)
    end
  end

  defp poll(offset \\ nil, previous \\ @reset) do
    case Nadia.get_updates(offset: offset, limit: 1, timeout: 20) do
      {:ok, []} -> poll(offset, previous)
      {:ok, [update]} ->
        {new_offset, new_previous} = ack_and_reply(update, previous)
        poll(new_offset, new_previous)
    end
  end

  defp ack_and_reply(%Nadia.Model.Update{update_id: update_id, message: message}, previous) do
    new_previous =
      if previous == @double_echo && message.text == previous do
        {:ok, _} = Nadia.send_message message.chat.id, @double_echo
        @reset
      else
        message.text
      end

    {update_id + 1, new_previous}
  end

  defp describe_chat(chat) do
    "#{chat.type}#{if chat.title, do: "##{chat.title}"}"
  end
end

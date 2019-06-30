defmodule Bloom.Bot do
  @reset :reset
  @double_echo Application.fetch_env!(:bloom, :double_echo)

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

  defp echo_locally(message),
    do: message |> describe_message() |> IO.puts()

  defp ack_and_reply(
         %Nadia.Model.Update{update_id: update_id, message: %Nadia.Model.Message{} = message},
         history
       ) do
    echo_locally(message)

    case message.text do
      nil ->
        {update_id + 1, history}

      _ ->
        new_subhistory =
          cond do
            message.text |> String.starts_with?("/weather") ->
              reply =
                case message.text do
                  "/weather " <> query ->
                    Bloom.Weather.describe(query)
                end

              {:ok, my_message} =
                Nadia.send_message(message.chat.id, reply,
                  parse_mode: "Markdown",
                  disable_web_page_preview: "True"
                )

              echo_locally(my_message)
              @reset

            message.text |> String.starts_with?("/eth") ->
              reply =
                case message.text do
                  "/eth " <> eth_entity ->
                    case eth_entity do
                      "me" ->
                        Bloom.Eth.describe("me", message.from.id)

                      _ ->
                        Bloom.Eth.describe(eth_entity)
                    end
                end

              {:ok, my_message} = Nadia.send_message(message.chat.id, reply)
              echo_locally(my_message)
              @reset

            message.text |> String.starts_with?("/lastfm") ->
              reply =
                case message.text do
                  "/lastfm" ->
                    Bloom.LastFM.describe(message.from.id)

                  "/lastfm " <> username ->
                    Bloom.LastFM.get_recent(username)

                  _ ->
                    "get lost"
                end

              {:ok, my_message} = Nadia.send_message(message.chat.id, reply)
              echo_locally(my_message)
              @reset

            message.text == Map.get(history, message.chat.id, @reset) && @double_echo ->
              {:ok, my_message} = Nadia.send_message(message.chat.id, message.text)
              echo_locally(my_message)
              @reset

            true ->
              message.text
          end

        with new_history = Map.put(history, message.chat.id, new_subhistory),
          do: {update_id + 1, new_history}
    end
  end

  defp ack_and_reply(%Nadia.Model.Update{update_id: update_id, message: message}, history)
       when is_nil(message) do
    echo_locally(message)
    {update_id + 1, history}
  end

  defp describe_message(%Nadia.Model.Message{} = message) do
    "{#{describe_chat(message.chat)}} " <>
      "[#{message.date |> DateTime.from_unix!() |> DateTime.to_iso8601()}] " <>
      "<#{describe_user(message.from)}>" <>
      "#{if length(message.photo) > 0, do: " [photo]"}" <>
      "#{if message.text, do: " #{message.text}"}"
  end

  defp describe_message(_) do
    "# Invalid message"
  end

  defp describe_chat(chat) do
    "#{chat.type}#{if chat.title, do: "##{chat.title}"}"
  end

  defp describe_user(%Nadia.Model.User{first_name: f, last_name: l, username: u, id: id}) do
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

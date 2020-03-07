defmodule Bloom.LastFM.User do
  @db "lastfm_users.txt"

  def start_link do
    Agent.start_link(fn -> get_users() end, name: __MODULE__)
  end

  def username(telegram_user_id) do
    Agent.get(__MODULE__, &Map.get(&1, telegram_user_id))
  end

  def memorize(telegram_user_id, username) do
    Agent.update(__MODULE__, &Map.put(&1, telegram_user_id, username))
    dump_users()
  end

  def table_for_db() do
    Agent.get(__MODULE__, & &1)
  end

  defp get_users() do
    case File.read(@db) do
      {:ok, s} ->
        s
        |> String.split("\n", trim: true)
        |> Enum.map(fn line ->
          [id, username] = String.split(line, " ")
          {String.to_integer(id), username}
        end)
        |> Enum.into(%{})

      {:error, _} ->
        %{}
    end
  end

  defp dump_users() do
    content =
      table_for_db()
      |> Enum.map(fn {k, v} -> "#{k} #{v}" end)
      |> Enum.join("\n")

    File.write(@db, content)
  end
end

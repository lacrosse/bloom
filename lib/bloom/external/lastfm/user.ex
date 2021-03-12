defmodule Bloom.External.LastFM.User do
  @db "lastfm_users.txt"

  def start_link do
    Agent.start_link(fn -> get_users() end, name: __MODULE__)
  end

  @spec username(integer) :: {:ok, String.t()} | :error
  def username(telegram_user_id) do
    Agent.get(__MODULE__, &Map.fetch(&1, telegram_user_id))
  end

  def memorize(telegram_user_id, username) do
    :ok = Agent.update(__MODULE__, &Map.put(&1, telegram_user_id, username))
    dump_users()
    {:ok, "Nice to meet you."}
  end

  def table_for_db() do
    Agent.get(__MODULE__, & &1)
  end

  defp get_users() do
    with {:ok, db} <- File.read(@db) do
      db
      |> String.split("\n", trim: true)
      |> Enum.map(fn line ->
        [id, username] = String.split(line, " ")
        {String.to_integer(id), username}
      end)
      |> Enum.into(%{})
    else
      {:error, _} -> %{}
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

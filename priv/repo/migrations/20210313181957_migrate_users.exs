defmodule Bloom.External.LastFM.User do
  @db "lastfm_users.txt"

  def start_link do
    Agent.start_link(fn -> get_users() end, name: __MODULE__)
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
end

defmodule Bloom.Repo.Migrations.MigrateUsers do
  use Ecto.Migration
  alias Bloom.User

  def up do
    Supervisor.start_link(
      [%{id: Bloom.External.LastFM.User, start: {Bloom.External.LastFM.User, :start_link, []}}],
      strategy: :one_for_one
    )

    Bloom.External.LastFM.User.table_for_db()
    |> Enum.map(fn {id, lastfm_username} ->
      %User{}
      |> User.changeset(%{id: id, lastfm_username: lastfm_username})
      |> Bloom.Repo.insert()
    end)
  end
end

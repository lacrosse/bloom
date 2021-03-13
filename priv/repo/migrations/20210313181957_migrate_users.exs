defmodule Bloom.Repo.Migrations.MigrateUsers do
  use Ecto.Migration
  alias Bloom.User

  def up do
    Supervisor.start_link(
      [%{id: Bloom.External.LastFM.User, start: {Bloom.External.LastFM.User, :start_link, []}}],
      strategy: :one_for_one
    )

    Bloom.External.LastFM.User.table_for_db()
    |> Enum.map(fn {telegram_id, lastfm_username} ->
      %User{}
      |> User.changeset(%{telegram_id: telegram_id, lastfm_username: lastfm_username})
      |> Bloom.Repo.insert()
    end)
  end
end

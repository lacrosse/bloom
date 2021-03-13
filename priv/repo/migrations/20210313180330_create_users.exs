defmodule Bloom.Repo.Migrations.CreateUsers do
  use Ecto.Migration

  def change do
    create table(:users, primary_key: false) do
      add(:id, :integer, primary_key: true)
      add(:lastfm_username, :string, size: 64)
    end
  end
end

defmodule Bloom.Repo.Migrations.CreateEthAddresses do
  use Ecto.Migration

  def change do
    create table(:eth_addresses, primary_key: false) do
      add(:public_key_fingerprint, :binary, primary_key: true, size: 20)
      add(:user_id, references(:users, on_delete: :delete_all))
    end
  end
end

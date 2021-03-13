defmodule Bloom.User do
  use Ecto.Schema
  import Ecto.Changeset
  alias Bloom.EthAddress

  @primary_key {:id, :integer, autogenerate: false}
  schema "users" do
    field(:lastfm_username, :string)

    has_many(:eth_addresses, EthAddress)
  end

  def changeset(user, params \\ %{}) do
    user
    |> cast(params, [:id, :lastfm_username])
    |> validate_required([:id])
    |> unique_constraint(:id)
  end
end

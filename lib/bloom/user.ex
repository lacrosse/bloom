defmodule Bloom.User do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:telegram_id, :integer, autogenerate: false}
  schema "users" do
    field(:lastfm_username, :string)
  end

  def changeset(user, params \\ %{}) do
    user
    |> cast(params, [:telegram_id, :lastfm_username])
    |> validate_required([:telegram_id])
    |> unique_constraint(:telegram_id)
  end
end

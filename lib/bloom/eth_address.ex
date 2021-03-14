defmodule Bloom.EthAddress do
  use Ecto.Schema
  import Ecto.Changeset
  import Ecto.Query
  alias Bloom.{Repo, User}

  @primary_key {:public_key_fingerprint, :binary, autogenerate: false}
  schema "eth_addresses" do
    field(:public_key_fingerprint_hex, :string, virtual: true)

    belongs_to(:user, User, references: :id)
  end

  def changeset(eth_address, params) do
    eth_address
    |> cast(params, [:public_key_fingerprint_hex, :user_id])
    |> validate_required([:public_key_fingerprint_hex, :user_id])
    |> cast_hex_to_bin()
    |> validate_byte_size(:public_key_fingerprint, 20)
    |> unique_constraint(:public_key_fingerprint)
  end

  def hex(%__MODULE__{public_key_fingerprint: fp}) do
    "0x" <> Base.encode16(fp, case: :lower)
  end

  @spec all_of_user(integer) :: Maybe.t([String.t()])
  def all_of_user(id) do
    from(a in __MODULE__, where: a.user_id == ^id)
    |> Repo.all()
    |> Enum.map(&bin_to_hex(&1.public_key_fingerprint))
    |> Maybe.wrap()
  end

  @spec all_of_user_reply(integer) :: Either.t(String.t())
  def all_of_user_reply(id) do
    all_of_user(id)
    |> Maybe.map(
      &(&1
        |> case do
          [] -> ["You don't have any ETH addresses."]
          hs -> ["You claimed these ETH addresses:" | hs]
        end
        |> Enum.join("\n"))
    )
    |> Maybe.to_either("Something went wrong.")
  end

  @spec add_to_user_reply(integer, String.t()) :: Either.t(String.t())
  def add_to_user_reply(id, hex) do
    %__MODULE__{}
    |> changeset(%{user_id: id, public_key_fingerprint_hex: hex})
    |> Repo.insert()
    |> Either.map_ok(&"You claimed #{bin_to_hex(&1.public_key_fingerprint)}.")
    |> Either.map_error(fn _ -> "Something went wrong." end)
  end

  @spec rm_from_user_reply(integer, String.t()) :: Either.t(String.t())
  def rm_from_user_reply(id, hex) do
    hex
    |> hex_to_bin()
    |> Maybe.flat_map(fn bin ->
      from(a in __MODULE__, where: a.user_id == ^id and a.public_key_fingerprint == ^bin)
      |> Repo.one()
      |> Maybe.wrap()
    end)
    |> Maybe.to_either("This is not your address.")
    |> Either.flat_map(
      &Repo.delete/1,
      &"You disowned #{bin_to_hex(&1.public_key_fingerprint)}.",
      fn _ -> "Something went wrong." end
    )
  end

  defp hex_to_bin(raw_hex) do
    with "0x" <> hex <- raw_hex,
         {:ok, bin} <- Base.decode16(hex, case: :mixed) do
      {:ok, bin}
    else
      _ -> :error
    end
  end

  defp cast_hex_to_bin(changeset) do
    with {:ok, raw_hex} <- fetch_change(changeset, :public_key_fingerprint_hex),
         {:ok, bin} <- hex_to_bin(raw_hex) do
      changeset
      |> delete_change(:public_key_fingerprint_hex)
      |> put_change(:public_key_fingerprint, bin)
    else
      _ ->
        changeset
        |> add_error(:public_key_fingerprint_hex, "malformed")
    end
  end

  defp validate_byte_size(changeset, field, length) do
    changeset
    |> validate_change(field, fn field, fp ->
      if byte_size(fp) == length,
        do: [],
        else: [{field, "should have exactly 20 bytes"}]
    end)
  end

  defp bin_to_hex(bin) do
    "0x" <> Base.encode16(bin, case: :lower)
  end
end

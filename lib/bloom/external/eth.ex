defmodule Bloom.External.Eth do
  alias __MODULE__.User

  @endpoint "https://api.etherscan.io/api"

  @spec net_worth(integer) :: Either.t(String.t())
  def net_worth(telegram_user_id) do
    with {:addresses, {:ok, addresses}} <- {:addresses, User.addresses(telegram_user_id)},
         {:balance, {:ok, results}} <- {:balance, account_balancemulti(addresses)} do
      ether =
        results
        |> Enum.map(&Decimal.new(&1["balance"]))
        |> Enum.reduce(Decimal.new(0), &Decimal.add/2)
        |> wei_to_ether()

      {:ok, "Your ethereal net worth is #{ether} Ξ."}
    else
      {:addresses, :error} -> {:error, "I don't know you."}
      {:balance, :error} -> {:error, "I can't see the balance."}
    end
  end

  @spec describe(String.t()) :: Either.t(String.t())
  def describe(entity)

  def describe(<<"0x", _::binary-size(40)>> = address) do
    case account_balance(address) do
      {:ok, wei} ->
        {:ok, "This is an Ethereum account and it has #{wei |> wei_to_ether()} Ξ."}

      :error ->
        {:ok, "This looks like an Ethereum account."}
    end
  end

  def describe(<<"0x", _txid::binary-size(64)>>) do
    {:ok, "This looks like an Ethereum transaction."}
  end

  def describe(_) do
    {:error, "I don't know what this is."}
  end

  defp wei_to_ether(wei) do
    wei_in_ether =
      10
      |> :math.pow(18)
      |> trunc()
      |> Decimal.new()

    wei
    |> Decimal.new()
    |> Decimal.div(wei_in_ether)
    |> Decimal.round(6)
    |> Decimal.normalize()
  end

  defp account_balance(address),
    do: etherscan_request("account", "balance", address: address, tag: "latest")

  defp account_balancemulti(addresses),
    do:
      etherscan_request("account", "balancemulti",
        address: Enum.join(addresses, ","),
        tag: "latest"
      )

  defp etherscan_request(module, action, args) do
    with kws = [module: module, action: action] ++ args,
         query = URI.encode_query(kws),
         url = "#{@endpoint}?#{query}",
         {:ok, %HTTPoison.Response{body: body}} <- HTTPoison.get(url),
         {:ok, %{"status" => "1", "result" => result}} <- Poison.decode(body) do
      {:ok, result}
    else
      _ -> :error
    end
  end
end

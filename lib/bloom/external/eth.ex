defmodule Bloom.External.Eth do
  @endpoint "https://api.etherscan.io/api"

  def describe(<<"0x", address::binary-size(40)>>) do
    case account_balance(address) do
      {:ok, wei} ->
        "This is an Ethereum account and it has #{wei |> wei_to_ether()} Ξ."

      :error ->
        "This looks like an Ethereum account, but I can't say anything else at this point."
    end
  end

  def describe(<<"0x", _txid::binary-size(64)>>) do
    "This looks like an Ethereum transaction."
  end

  def describe(_) do
    "Not sure what this is, check your privilege."
  end

  def describe("me", telegram_user_id) do
    case Bloom.External.Eth.User.addresses(telegram_user_id) do
      nil ->
        "I don't know you."

      addresses ->
        case account_balancemulti(addresses) do
          {:ok, results} ->
            ether =
              results
              |> Enum.map(&Decimal.new(&1["balance"]))
              |> Enum.reduce(Decimal.new(0), &Decimal.add/2)
              |> wei_to_ether()

            "Your ethereal net worth is #{ether} Ξ."

          :error ->
            "I can't say anything at this point."
        end
    end
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
    |> Decimal.reduce()
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
         {:ok, %{"result" => result}} <- Poison.decode(body) do
      {:ok, result}
    else
      _ -> :error
    end
  end
end

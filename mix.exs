defmodule Bloom.Mixfile do
  use Mix.Project

  def project do
    [app: :bloom,
     version: "0.0.1",
     elixir: "~> 1.2",
     build_embedded: Mix.env == :prod,
     start_permanent: Mix.env == :prod,
     deps: deps()]
  end

  def application do
    [applications: [
      :logger,
      :nadia],
     mod: {Bloom, []}]
  end

  defp deps do
    [
      {:nadia, "~> 0.3"}
    ]
  end
end

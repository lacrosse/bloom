defmodule Bloom.Mixfile do
  use Mix.Project

  def project do
    [app: :bloom,
     version: "0.0.1",
     elixir: "~> 1.4",
     build_embedded: Mix.env == :prod,
     start_permanent: Mix.env == :prod,
     deps: deps()]
  end

  def application do
    [extra_applications: [:logger],
     mod: {Bloom, []}]
  end

  defp deps do
    [
      {:nadia, "~> 0.3"},
      {:httpoison, "~> 0.12"},
      {:poison, "~> 3.1", runtime: false},
      {:decimal, "~> 1.0", runtime: false}
    ]
  end
end

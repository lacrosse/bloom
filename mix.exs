defmodule Bloom.Mixfile do
  use Mix.Project

  def project do
    [
      app: :bloom,
      version: "0.0.3",
      elixir: "~> 1.9",
      build_embedded: Mix.env() == :prod,
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  def application do
    [extra_applications: [:logger, :ecto], mod: {Bloom, []}]
  end

  defp deps do
    [
      {:nadia, "~> 0.7.0"},
      {:httpoison, "~> 1.7.0"},
      {:poison, "~> 3.1", runtime: false},
      {:decimal, "~> 1.0", runtime: false},
      {:jason, "~> 1.2.2"},
      {:sqlite_ecto2, "~> 2.2"}
    ]
  end
end

defmodule Routeros.Mixfile do
  use Mix.Project

  def project do
    [
      app: :routeros,
      version: "0.1.0",
      elixir: "~> 1.14",
      build_embedded: Mix.env() == :prod,
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  def application do
    [extra_applications: [:logger], mod: {Routeros, []}]
  end

  defp deps do
    [
      {:styler, "~> 0.5", only: [:dev, :test], runtime: false},
      {:credo, "~> 1.7", only: [:dev, :test], runtime: false}
    ]
  end
end

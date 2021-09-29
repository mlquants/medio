defmodule Medio.MixProject do
  use Mix.Project

  def project do
    [
      app: :medio,
      version: "0.1.0",
      elixir: "~> 1.12",
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger],
      mod: {Medio.Application, []}
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:msgpax, "~> 2.3.0"},
      {:uuid, "~> 1.1"},
      {:credo, "~> 1.5", only: [:test, :dev], runtime: false}
    ]
  end
end

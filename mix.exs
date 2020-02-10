defmodule OpencensusEcto.MixProject do
  use Mix.Project

  def project do
    [
      app: :opencensus_ecto,
      version: "0.1.0",
      elixir: "~> 1.8",
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    []
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:telemetry, "~> 0.4.0"},
      {:opencensus, "~> 0.9.0"}
    ]
  end
end

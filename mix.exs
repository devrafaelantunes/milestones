defmodule Milestones.MixProject do
  use Mix.Project

  def project do
    [
      app: :milestones,
      version: "0.1.0",
      elixir: "~> 1.13",
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger],
      mod: {Milestones.Application, []}
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:apex, "~>1.2.1"},
      {:flow, "~> 1.0"}
    ]
  end
end

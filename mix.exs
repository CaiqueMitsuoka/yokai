defmodule Yokai.MixProject do
  use Mix.Project

  def project do
    [
      app: :yokai,
      version: "0.1.0",
      elixir: "~> 1.17-rc",
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  def cli do
    [
      preferred_envs: [{:watch, :test}]
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger]
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:file_system, "~> 1.0"}
    ]
  end
end

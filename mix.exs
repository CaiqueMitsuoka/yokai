defmodule Yokai.MixProject do
  use Mix.Project

  def project do
    [
      app: :yokai,
      description: "A test runner and watcher designed for fast interactive development",
      version: "0.2.0",
      elixir: "~> 1.17",
      package: package(),
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      docs: [
        extras: ["README.md"]
      ]
    ]
  end

  def package do
    [
      licenses: ["MIT"],
      links: %{
        "GitHub" => "https://github.com/CaiqueMitsuoka/yokai"
      },
      source_url: "https://github.com/CaiqueMitsuoka/yokai"
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
      {:ex_doc, ">= 0.0.0", only: :dev, runtime: false},
      {:file_system, "~> 1.0"}
    ]
  end
end

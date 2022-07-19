defmodule ElasticSearchStream.MixProject do
  use Mix.Project

  def project do
    [
      app: :elastic_search_stream,
      version: "0.1.0",
      elixir: "~> 1.13",
      start_permanent: Mix.env() == :prod,
      deps: deps()
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
      {:confex, "~> 3.4"},
      {:dialyxir, "~> 1.1", only: [ :dev, :test], runtime: false},
      {:httpoison, "~> 1.8.1"},
      {:poison, "~> 5.0"},
      {:req, "~> 0.2.2"},
      # {:dep_from_hexpm, "~> 0.3.0"},
      # {:dep_from_git, git: "https://github.com/elixir-lang/my_dep.git", tag: "0.1.0"}
    ]
  end
end

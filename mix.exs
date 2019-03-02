defmodule ElasticConsumer.MixProject do
  use Mix.Project

  def project do
    [
      app: :elastic_consumer,
      version: "0.1.0",
      elixir: "~> 1.8",
      build_embedded: Mix.env() == :prod,
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger, :plug_cowboy],
      mod: {ElasticConsumer.Application, []}
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      # {:dep_from_hexpm, "~> 0.3.0"},
      # {:dep_from_git, git: "https://github.com/elixir-lang/my_dep.git", tag: "0.1.0"}
      {:gen_rmq, git: "https://github.com/seechinsu/gen_rmq"},
      {:jason, "~> 1.1"},
      {:plug_cowboy, "~> 2.0"},
      {:elastix, "~> 0.7.1"}
    ]
  end
end

defmodule CurrencyConversion.Mixfile do
  use Mix.Project

  @version "0.3.0"

  def project do
    [app: :currency_conversion,
     docs: docs(),
     version: @version,
     elixir: "~> 1.3",
     description: description(),
     package: package(),
     build_embedded: Mix.env == :prod,
     start_permanent: Mix.env == :prod,
     deps: deps(),
     test_coverage: [tool: ExCoveralls]]
  end

  defp description do
    """
    Convert Money Amounts between currencies.
    """
  end

  def application do
    [applications: [:logger, :httpotion], mod: {CurrencyConversion.Application, []}]
  end

  defp deps do
    [{:httpotion, "~> 3.0.2"},
     {:poison, "~> 3.0"},
     {:money, "~> 1.2.1"},
     {:mock, "~> 0.2.0", only: :test},
     {:ex_doc, ">= 0.0.0", only: :dev},
     {:inch_ex, only: :docs},
     {:excoveralls, "~> 0.4", only: [:dev, :test]},
     {:dialyxir, "~> 0.4", only: [:dev], runtime: false},
     {:credo, "~> 0.5", only: [:dev, :test]}]
  end

  defp package do
    [name: :currency_conversion,
     files: ["lib", "mix.exs", "README*", "LICENSE*"],
     maintainers: ["Jonatan Männchen"],
     licenses: ["MIT"],
     links: %{"GitHub" => "https://github.com/jshmrtn/currency-conversion"}]
  end

  def docs do
    [source_ref: "v#{@version}",
     source_url: "https://github.com/jshmrtn/currency-conversion"]
  end
end

defmodule CurrencyConversion.Source.TestTest do
  @moduledoc false

  use ExUnit.Case, async: false
  doctest CurrencyConversion.Source.Test, except: [load: 0]

  import CurrencyConversion.Source.Test

  describe "load/0" do
    test "when configuration is missing" do
      Application.delete_env(:currency_conversion, :test_rates)
      {:ok, rates} = load()
      assert default_rates() == rates
    end

    @override_rates %CurrencyConversion.Rates{base: :EUR, rates: %{CHF: 7.0}}
    test "when configuration is present" do
      Application.put_env(:currency_conversion, :test_rates, @override_rates)
      {:ok, rates} = load()
      assert @override_rates == rates
    end

    @override_rates_tuple {:EUR, %{CHF: 7.0}}
    test "when configuration is present in tuple style" do
      Application.put_env(:currency_conversion, :test_rates, @override_rates_tuple)
      {:ok, rates} = load()
      assert @override_rates == rates
    end
  end
end

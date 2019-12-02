defmodule CurrencyConversion.Source.TestTest do
  @moduledoc false

  use ExUnit.Case, async: true

  doctest CurrencyConversion.Source.Test, except: [load: 0]

  import CurrencyConversion.Source.Test

  describe "load/0" do
    test "when configuration is missing" do
      {:ok, rates} = load([])
      assert default_rates() == rates
    end

    @override_rates %CurrencyConversion.Rates{base: :EUR, rates: %{CHF: 7.0}}
    test "when configuration is present" do
      {:ok, rates} = load(test_rates: @override_rates)
      assert @override_rates == rates
    end

    @override_rates_tuple {:EUR, %{CHF: 7.0}}
    test "when configuration is present in tuple style" do
      {:ok, rates} = load(test_rates: @override_rates_tuple)
      assert @override_rates == rates
    end
  end
end

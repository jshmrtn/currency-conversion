defmodule CurrencyConversionTest do
  @moduledoc false

  use ExUnit.Case, async: false

  doctest CurrencyConversion

  alias CurrencyConversion.Source.Test, as: TestSource

  defmodule Converter do
    @moduledoc false

    use CurrencyConversion, otp_app: :currency_conversion
  end

  setup tags do
    Application.put_env(
      :currency_conversion,
      Converter,
      Enum.to_list(tags) ++ [source: TestSource]
    )

    start_supervised!(Converter)

    :ok
  end

  describe "convert/2" do
    @tag test_rates: %CurrencyConversion.Rates{base: :EUR, rates: %{CHF: 0.5, USD: 0.75}}
    test "7.00 CHF => EUR => USD" do
      assert %Money{amount: 10_50, currency: :USD} =
               Converter.convert(Money.new(7_00, :CHF), :USD)
    end

    @tag test_rates: %CurrencyConversion.Rates{base: :EUR, rates: %{CHF: 0.5, USD: 0.75}}
    test "7.00 EUR => USD" do
      assert %Money{amount: 5_25, currency: :USD} = Converter.convert(Money.new(7_00, :EUR), :USD)
    end

    @tag test_rates: %CurrencyConversion.Rates{base: :EUR, rates: %{BIF: 1000}}
    test "7.00 EUR => BIF" do
      assert %Money{amount: 700_000, currency: :BIF} =
               Converter.convert(Money.new(7_00, :EUR), :BIF)
    end

    @tag test_rates: %CurrencyConversion.Rates{base: :EUR, rates: %{CHF: 0.5, USD: 0.75}}
    test "7.00 CHF => EUR" do
      assert %Money{amount: 14_00, currency: :EUR} =
               Converter.convert(Money.new(7_00, :CHF), :EUR)
    end

    @tag test_rates: %CurrencyConversion.Rates{base: :EUR, rates: %{CHF: 0.5, USD: 0.75}}
    test "0.00 CHF => EUR" do
      assert %Money{amount: 0_00, currency: :EUR} = Converter.convert(Money.new(0_00, :CHF), :EUR)
    end

    @tag test_rates: %CurrencyConversion.Rates{base: :EUR, rates: %{CHF: 0.5, USD: 0.75}}
    test "7.20 CHF => CHF" do
      assert %Money{amount: 7_20, currency: :CHF} = Converter.convert(Money.new(7_20, :CHF), :CHF)
    end
  end

  describe "get_currencies/0" do
    test "fetches all currencies" do
      assert [
               TestSource.default_rates().base
               | Enum.sort(Map.keys(CurrencyConversion.Source.Test.default_rates().rates))
             ] ==
               Converter.get_currencies()
    end
  end

  describe "get_rates/0" do
    test "fetches current rates" do
      assert Converter.get_rates() == TestSource.default_rates()
    end
  end

  describe "refresh_rates/0" do
    test "refreshes rates" do
      assert Converter.refresh_rates() == :ok
    end
  end
end

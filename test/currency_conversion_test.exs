defmodule CurrencyConversionTest do
  @moduledoc false

  use ExUnit.Case, async: true

  doctest CurrencyConversion

  defmodule Converter do
    @moduledoc false

    use CurrencyConversion, otp_app: :currency_conversion
  end

  setup_all do
    Application.put_env(:currency_conversion, Converter, source: CurrencyConversion.Source.Test)
    start_supervised!(Converter)
    :ok
  end

  describe "get_currencies/0" do
    test "fetches all currencies" do
      assert Converter.get_currencies() == [
               :EUR,
               :AUD,
               :BGN,
               :BRL,
               :CAD,
               :CHF,
               :CNY,
               :CZK,
               :DKK,
               :GBP,
               :HKD,
               :HRK,
               :HUF,
               :IDR,
               :ILS,
               :INR,
               :JPY,
               :KRW,
               :MXN,
               :MYR,
               :NOK,
               :NZD,
               :PHP,
               :PLN,
               :RON,
               :RUB,
               :SEK,
               :SGD,
               :THB,
               :TRY,
               :USD,
               :ZAR
             ]
    end
  end
end

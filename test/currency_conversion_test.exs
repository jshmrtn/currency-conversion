defmodule CurrencyConversionTest do
  @moduledoc false

  use ExUnit.Case, async: false

  setup_all do
    start_supervised!({CurrencyConversion.UpdateWorker, source: CurrencyConversion.Source.Test})
    :ok
  end

  doctest CurrencyConversion

  describe "get_currencies/0" do
    test "fetches all currencies" do
      assert CurrencyConversion.get_currencies() == [
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

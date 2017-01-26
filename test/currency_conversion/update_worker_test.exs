defmodule CurrencyConversion.UpdateWorkerTest do
  use ExUnit.Case, async: false
  doctest CurrencyConversion.UpdateWorker

  import CurrencyConversion.UpdateWorker

  import ExUnit.CaptureLog

  defmodule Source do
    @behaviour CurrencyConversion.Source

    def load do
      {:ok, %CurrencyConversion.Rates{base: :CHF, rates: %{}}}
    end
  end

  test "initial load called" do
    capture_log(fn ->
      Application.stop(:currency_conversion)
      Application.put_env(:currency_conversion, :source, CurrencyConversion.UpdateWorkerTest.Source)
      Application.ensure_started(:logger)
      Application.ensure_all_started(:currency_conversion)
    end)

    assert get_rates() == %CurrencyConversion.Rates{base: :CHF, rates: %{}}
  end
end

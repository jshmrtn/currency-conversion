defmodule CurrencyConversion.Source.Fixer do
  @moduledoc """
  Currency Conversion Source for http://fixer.io/
  """

  alias Poison.Parser

  @behaviour CurrencyConversion.Source
  @default_protocol "http"
  @base_endpoint "data.fixer.io/api/latest"
  @doc """
  Load current currency rates from fixer.io.

  ### Examples

      iex> CurrencyConversion.Source.Fixer.load
      {:ok, %CurrencyConversion.Rates{base: :EUR,
        rates: %{AUD: 1.4205, BGN: 1.9558, BRL: 3.4093, CAD: 1.4048, CHF: 1.0693,
         CNY: 7.3634, CZK: 27.021, DKK: 7.4367, GBP: 0.85143, HKD: 8.3006,
         HRK: 7.48, HUF: 310.98, IDR: 14316.0, ILS: 4.0527, INR: 72.957,
         JPY: 122.4, KRW: 1248.1, MXN: 22.476, MYR: 4.739, NOK: 8.9215,
         NZD: 1.4793, PHP: 53.373, PLN: 4.3435, RON: 4.4943, RUB: 64.727,
         SEK: 9.466, SGD: 1.5228, THB: 37.776, TRY: 4.1361, USD: 1.07,
         ZAR: 14.31}}}

  """
  def load do
    case HTTPotion.get(base_url(), query: %{access_key: get_access_key()}) do
      %HTTPotion.Response{body: body, status_code: 200} -> parse(body)
      _ -> {:error, "Fixer.io API unavailable."}
    end
  end

  defp parse(body) do
    case Parser.parse(body) do
      {:ok, data} -> interpret(data)
      _ -> {:error, "JSON decoding of response body failed."}
    end
  end

  defp interpret(%{"base" => base, "rates" => rates = %{}}) do
    case interpret_rates(Map.to_list(rates)) do
      {:ok, interpreted_rates} -> {:ok, %CurrencyConversion.Rates{
        base: String.to_atom(base),
        rates: interpreted_rates
      }}
      error -> error
    end
  end
  defp interpret(_data), do: {:error, "Fixer API Schema has changed."}

  defp interpret_rates(rates, accumulator \\ %{})

  defp interpret_rates([{currency, rate} | tail], accumulator) when is_binary(currency) and (is_float(rate) or is_integer(rate)) do
    interpret_rates(tail, Map.put(accumulator, String.to_atom(currency), rate))
  end

  defp interpret_rates([_ | _], _), do: {:error, "Fixer API Schema has changed."}
  defp interpret_rates([], accumulator), do: {:ok, accumulator}

  defp base_url, do: get_protocol() <> "://" <> @base_endpoint

  defp get_access_key, do: Application.get_env(:currency_conversion, :source_api_key)
  defp get_protocol, do: Application.get_env(:currency_conversion, :source_protocol, @default_protocol)
end

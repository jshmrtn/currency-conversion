with {:module, _module} <- Code.ensure_compiled(Jason),
     {:module, _module} <- Code.ensure_compiled(HTTPotion) do
  defmodule CurrencyConversion.Source.ExchangeRatesApi do
    @moduledoc """
    Currency Conversion Source for http://exchangeratesapi.io/

    Please add `jason` and `httpotion` to your `deps` in your `mix.exs` to use this source.

        def deps do
          [
            {:currency_conversion, "~> 0.3"},
            {:jason, "~> 1.1"},
            {:httpotion, "~> 3.1"}
          ]
        end

    """

    @behaviour CurrencyConversion.Source

    @default_protocol "https"
    @base_endpoint "api.exchangeratesapi.io/latest"
    @default_base_currency :EUR

    @doc """
    Load current currency rates from exchangeratesapi.io.

    ### Examples

        iex> CurrencyConversion.Source.ExchangeRatesApi.load([])
        {:ok, %CurrencyConversion.Rates{base: :EUR,
          rates: %{AUD: 1.4205, BGN: 1.9558, BRL: 3.4093, CAD: 1.4048, CHF: 1.0693,
           CNY: 7.3634, CZK: 27.021, DKK: 7.4367, GBP: 0.85143, HKD: 8.3006,
           HRK: 7.48, HUF: 310.98, IDR: 14316.0, ILS: 4.0527, INR: 72.957,
           JPY: 122.4, KRW: 1248.1, MXN: 22.476, MYR: 4.739, NOK: 8.9215,
           NZD: 1.4793, PHP: 53.373, PLN: 4.3435, RON: 4.4943, RUB: 64.727,
           SEK: 9.466, SGD: 1.5228, THB: 37.776, TRY: 4.1361, USD: 1.07,
           ZAR: 14.31}}}

    """
    @impl CurrencyConversion.Source
    def load(opts) do
      base_currency = Keyword.get(opts, :base_currency, @default_base_currency)
      protocol = Keyword.get(opts, :source_protocol, @default_protocol)
      base_url = protocol <> "://" <> @base_endpoint
      access_key = Keyword.fetch!(opts, :source_api_key)

      case HTTPotion.get(base_url, query: %{base: base_currency, access_key: access_key}) do
        %HTTPotion.Response{body: body, status_code: 200} -> parse(body)
        _ -> {:error, "Exchange Rates API unavailable."}
      end
    end

    defp parse(body) do
      data = Jason.decode!(body)
      interpret(data)
    rescue
      Jason.DecodeError ->
        {:error, "JSON decoding of response body failed."}
    end

    defp interpret(%{"base" => base, "rates" => rates = %{}}) do
      case interpret_rates(Map.to_list(rates)) do
        {:ok, interpreted_rates} ->
          {:ok,
           %CurrencyConversion.Rates{
             base: String.to_atom(base),
             rates: interpreted_rates
           }}

        error ->
          error
      end
    end

    defp interpret(_data), do: {:error, "Exchange Rates API Schema has changed."}

    defp interpret_rates(rates, accumulator \\ %{})

    defp interpret_rates([{currency, rate} | tail], accumulator)
         when is_binary(currency) and (is_float(rate) or is_integer(rate)) do
      interpret_rates(tail, Map.put(accumulator, String.to_atom(currency), rate))
    end

    defp interpret_rates([_ | _], _), do: {:error, "Exchange Rates API Schema has changed."}
    defp interpret_rates([], accumulator), do: {:ok, accumulator}
  end
end

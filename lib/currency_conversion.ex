defmodule CurrencyConversion do
  @moduledoc """
  Module to Convert Currencies.
  """

  alias CurrencyConversion.Rates
  alias CurrencyConversion.UpdateWorker

  @doc """
  Convert from currency A to B.

  ### Example

      iex> CurrencyConversion.convert(Money.new(7_00, :CHF), :USD, %CurrencyConversion.Rates{base: :EUR,
      ...>  rates: %{CHF: 0.5, USD: 0.75}})
      %Money{amount: 10_50, currency: :USD}

      iex> CurrencyConversion.convert(Money.new(7_00, :EUR), :USD, %CurrencyConversion.Rates{base: :EUR,
      ...>  rates: %{CHF: 0.5, USD: 0.75}})
      %Money{amount: 5_25, currency: :USD}

      iex> CurrencyConversion.convert(Money.new(7_00, :CHF), :EUR, %CurrencyConversion.Rates{base: :EUR,
      ...>  rates: %{CHF: 0.5, USD: 0.75}})
      %Money{amount: 14_00, currency: :EUR}

      iex> CurrencyConversion.convert(Money.new(0, :CHF), :EUR, %CurrencyConversion.Rates{base: :EUR,
      ...>  rates: %{CHF: 0.5, USD: 0.75}})
      %Money{amount: 0, currency: :EUR}

      iex> CurrencyConversion.convert(Money.new(7_20, :CHF), :CHF, %CurrencyConversion.Rates{base: :EUR,
      ...>  rates: %{CHF: 0.5, USD: 0.75}})
      %Money{amount: 7_20, currency: :CHF}

  """
  @spec convert(Money.t, atom, Rates.t) :: Money.t
  def convert(amount, to_currency, rates \\ UpdateWorker.get_rates())
  def convert(%Money{amount: 0}, to_currency, _), do: Money.new(0, to_currency)
  def convert(amount = %Money{currency: currency}, currency, _), do: amount
  def convert(%Money{amount: amount, currency: currency}, to_currency, %Rates{base: currency, rates: rates}) do
    Money.new(round(amount * Map.fetch!(rates, to_currency)), to_currency)
  end
  def convert(%Money{amount: amount, currency: currency}, to_currency, %Rates{base: to_currency, rates: rates}) do
    Money.new(round(amount / Map.fetch!(rates, currency)), to_currency)
  end
  def convert(amount, to_currency, rates) do
    convert(convert(amount, rates.base, rates), to_currency, rates)
  end

  @doc """
  Get all currencies

  ### Examples

      iex> CurrencyConversion.get_currencies(%CurrencyConversion.Rates{base: :EUR,
      ...>  rates: %{CHF: 0.5, USD: 0.75}})
      [:EUR, :CHF, :USD]

  """
  @spec get_currencies(Rates.t) :: [atom]
  def get_currencies(rates \\ UpdateWorker.get_rates())
  def get_currencies(%Rates{base: base, rates: rates}), do: [base | Map.keys(rates)]
end

defmodule CurrencyConversion.Rates do
  @moduledoc """
  This is the `CurrencyConversion.Rates` struct.
  """

  @type t :: %CurrencyConversion.Rates{
          base: atom,
          rates: %{atom => float | integer}
        }

  @doc """
  Defines a Currency DataSet

  ### Values
  - `base` - Defines the base currency (all other currencies are derived from the base currency)
    * Type: `atom`
    * Example: `:CHF`
  - `rates`
    * Type: `%{atom => float}`
    * Example: `%{CHF: 1.23, EUR: 1.132}`

  ### Examples

      iex> %CurrencyConversion.Rates{base: :EUR, rates: %{AUD: 1.4205, BGN: 1.9558}}
      %CurrencyConversion.Rates{base: :EUR, rates: %{AUD: 1.4205, BGN: 1.9558}}
  """
  @enforce_keys [:base, :rates]
  defstruct [:base, :rates]

  @doc false
  @spec to_list(CurrencyConversion.Rates.t()) :: [{atom, float | integer} | {:base, atom}]
  def to_list(%__MODULE__{base: base, rates: rates}) do
    [{:base, base} | Enum.to_list(rates)]
  end

  @doc false
  @spec from_list(list :: [{atom, float | integer} | {:base, atom}]) ::
          CurrencyConversion.Rates.t()
  def from_list(list) when is_list(list) do
    Enum.reduce(
      list,
      %__MODULE__{base: nil, rates: %{}},
      fn
        {:base, base}, %__MODULE__{rates: rates} when is_atom(base) ->
          %__MODULE__{base: base, rates: rates}

        {currency, rate}, %__MODULE__{base: base, rates: rates}
        when is_atom(currency) and (is_float(rate) or is_integer(rate)) ->
          %__MODULE__{base: base, rates: Map.put_new(rates, currency, rate)}
      end
    )
  end
end

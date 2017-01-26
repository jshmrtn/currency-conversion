defmodule CurrencyConversion.Rates do
  @moduledoc """
  This is the `CurrencyConversion.Rates` struct.
  """

  @type t :: %CurrencyConversion.Rates{
    base: atom,
    rates: %{atom => float}
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
end

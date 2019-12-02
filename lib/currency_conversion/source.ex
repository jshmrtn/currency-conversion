defmodule CurrencyConversion.Source do
  @moduledoc """
  Behaviour for all currency rate sources.
  """

  @callback load(opts :: Keyword.t()) :: {:ok, CurrencyConversion.Rates.t()} | {:error, binary}
end

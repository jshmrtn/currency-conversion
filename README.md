# CurrencyConversion

[![GitHub license](https://img.shields.io/badge/license-MIT-blue.svg)](https://raw.githubusercontent.com/jshmrtn/currency-conversion/master/LICENSE)
[![Build Status](https://travis-ci.org/jshmrtn/currency-conversion.svg?branch=master)](https://travis-ci.org/jshmrtn/currency-conversion)
[![Hex.pm Version](https://img.shields.io/hexpm/v/currency_conversion.svg?style=flat)](https://hex.pm/packages/currency_conversion)
[![InchCI](https://inch-ci.org/github/jshmrtn/currency-conversion.svg?branch=master)](https://inch-ci.org/github/jshmrtncurrency-conversion)
[![Coverage Status](https://coveralls.io/repos/github/jshmrtn/currency-conversion/badge.svg?branch=master)](https://coveralls.io/github/jshmrtn/currency-conversion?branch=master)

Convert Money Amounts between currencies. This library uses an OTP worker to save current conversion rates.

## Installation

The package can be installed by adding `currency_conversion` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [{:currency_conversion, "~> 0.3.1"}]
end
```

## Configuration

- `source` - Configure which Data Source Should Be Used.
  * Type: `atom`
  * Default: `CurrencyConversion.Source.Fixer`
  * Restrictions: Must implement `CurrencyConversion.Source` behaviour
  * Given Implementations:
    - `CurrencyConversion.Source.Fixer` - Fixer IO
    - `CurrencyConversion.Source.Test` - Test Source
- `refresh_interval` - Configure how often the data should be refreshed. (in ms)
  * Type: `integer`
  * Default: `86_400_000` (Once per Day)
- `test_rates` - Configure rates for `CurrencyConversion.Source.Test` source
  * Type: `{atom, %{atom: float}}`
  * Default: see `CurrencyConversion.Source.Test.@default_rates`
  * Example: `{:EUR, %{CHF: 7}}`

```elixir
config :currency_conversion,
  source: CurrencyConversion.Source.Fixer,
  source_api_key: "FIXER_ACCESS_KEY",
  # defaults to http since free access key only supports http
  source_protocol: "https",
  refresh_interval: 86_400_000
```

## Custom Source

A custom source can be implemented by using the behaviour `CurrencyConversion.Source` and reconfiguring the `source` config.

It only has to implement the function `load/0`, which produces a struct of type `%CurrencyConversion.Rates{}`.

## Test

To prevent HTTP calls in the Tests, configure the Test Source. (See the configuration `test_rates` for custom test rates.)

```elixir
config :currency_conversion,
  source: CurrencyConversion.Source.Test,
  refresh_interval: 86_400_000
```

## Usage

Only the function `CurrencyConversion.convert/3` is exposed to the user. The library [money](https://github.com/liuggio/money) is used to represent money amounts.

### Example

```elixir
iex> CurrencyConversion.convert(Money.new(7_00, :CHF), :USD)
%Money{amount: 10_50, currency: :USD}
```

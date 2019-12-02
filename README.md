# CurrencyConversion

[![GitHub license](https://img.shields.io/badge/license-MIT-blue.svg)](https://raw.githubusercontent.com/jshmrtn/currency-conversion/master/LICENSE)
[![Build Status](https://travis-ci.org/jshmrtn/currency-conversion.svg?branch=master)](https://travis-ci.org/jshmrtn/currency-conversion)
[![Hex.pm Version](https://img.shields.io/hexpm/v/currency_conversion.svg?style=flat)](https://hex.pm/packages/currency_conversion)
[![Coverage Status](https://coveralls.io/repos/github/jshmrtn/currency-conversion/badge.svg?branch=master)](https://coveralls.io/github/jshmrtn/currency-conversion?branch=master)

Convert Money Amounts between currencies. This library uses an OTP worker to save current conversion rates.

## Installation

The package can be installed by adding `currency_conversion` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:currency_conversion, "~> 0.3"},
    {:jason, "~> 1.1"}, # When usig Fixer / Exchange Rates API,
    {:httpotion, "~> 3.1"}, # When usig Fixer / Exchange Rates API
  ]
end
```

## Setup

`CurrencyConversion` is a wrapper around the currency conversion. We can define an
implementation as follows:

```elixir
defmodule MyApp.CurrencyConversion do
  use CurrencyConversion, otp_app: :my_app
end
```

If your application was generated with a supervisor (by passing `--sup` to `mix new`)
you will have a `lib/my_app/application.ex` file containing the application start
callback that defines and starts your supervisor. You just need to edit the `start/2`
function to start the converter as a supervisor on your application's supervisor:

```elixir
def start(_type, _args) do
  children = [
    {MyApp.CurrencyConversion, []}
  ]
  opts = [strategy: :one_for_one, name: MyApp.Supervisor]
  Supervisor.start_link(children, opts)
end
```

## Configuration

- `source` - Configure which Data Source Should Be Used.
  * Type: `atom`
  * Default: `CurrencyConversion.Source.Fixer`
  * Restrictions: Must implement `CurrencyConversion.Source` behaviour
  * Given Implementations:
    - `CurrencyConversion.Source.Fixer` - [Fixer](https://fixer.io/)
    - `CurrencyConversion.Source.ExchangeRatesApi` - [Exchange Rates API](https://exchangeratesapi.io/)
    - `CurrencyConversion.Source.Test` - Test Source
- `base_currency` - Change the base currency that is requested when fetching rates
  * Type: `atom`
  * Default: `:EUR`
- `refresh_interval` - Configure how often the data should be refreshed. (in ms)
  * Type: `integer`
  * Default: `86_400_000` (Once per Day)
- `test_rates` - Configure rates for `CurrencyConversion.Source.Test` source
  * Type: `{atom, %{atom: float}}`
  * Default: see `CurrencyConversion.Source.Test.@default_rates`
  * Example: `{:EUR, %{CHF: 7.0}}`

```elixir
config :my_app, MyApp.CurrencyConversion,
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
config :my_app, MyApp.CurrencyConversion,
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

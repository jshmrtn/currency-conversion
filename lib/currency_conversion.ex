defmodule CurrencyConversion do
  @moduledoc """
  Module to Convert Currencies.

  `CurrencyConversion` is a wrapper around the currency conversion. We can define an
  implementation as follows:

      defmodule MyApp.CurrencyConversion do
        use CurrencyConversion, otp_app: :my_app
      end

  Where the configuration for the Converter must be in your application environment,
  usually defined in your `config/config.exs`:

      config :my_app, MyApp.CurrencyConversion,
        source: MyApp.CurrencyConversion.Source.CustomSource

  If your application was generated with a supervisor (by passing `--sup` to `mix new`)
  you will have a `lib/my_app/application.ex` file containing the application start
  callback that defines and starts your supervisor. You just need to edit the `start/2`
  function to start the converter as a supervisor on your application's supervisor:

      def start(_type, _args) do
        children = [
          {MyApp.CurrencyConversion, []}
        ]
        opts = [strategy: :one_for_one, name: MyApp.Supervisor]
        Supervisor.start_link(children, opts)
      end

  """

  @callback convert(amount :: Money.t(), to_currency :: atom) :: Money.t()
  @callback get_currencies :: [atom]

  defmacro __using__(opts) do
    otp_app = Keyword.fetch!(opts, :otp_app)

    quote do
      @moduledoc """
      Module to Convert Currencies for `#{unquote(otp_app)}`.
      """

      @behaviour unquote(__MODULE__)

      @update_worker Module.concat(__MODULE__, UpdateWorker)
      @otp_app unquote(otp_app)

      alias CurrencyConversion.UpdateWorker

      use Supervisor

      @doc false
      def start_link(_opts) do
        Supervisor.start_link(__MODULE__, nil, name: __MODULE__)
      end

      @doc false
      def child_spec(init_arg) do
        super(init_arg)
      end

      @impl Supervisor
      def init(_init_arg) do
        config = Application.get_env(@otp_app, __MODULE__, [])

        Supervisor.init([{UpdateWorker, config ++ [name: @update_worker]}], strategy: :one_for_one)
      end

      @doc """
      Convert from currency A to B.

      ### Example

          iex> #{__MODULE__}.convert(Money.new(7_00, :CHF), :USD)
          %Money{amount: 7_03, currency: :USD}

      """
      @impl unquote(__MODULE__)
      def convert(amount, to_currency) do
        unquote(__MODULE__).convert(amount, to_currency, UpdateWorker.get_rates(@update_worker))
      end

      @doc """
      Get all currencies

      ### Examples

          iex> #{__MODULE__}.get_currencies()
          [:EUR, :CHF, :USD]

      """
      @impl unquote(__MODULE__)
      def get_currencies do
        unquote(__MODULE__).get_currencies(UpdateWorker.get_rates(@update_worker))
      end

      @doc """
      Get current exchange rates

      ### Examples

          iex> #{__MODULE__}.get_rates()
          %CurrencyConversion.Rates{
              base: :EUR,
              rates: %{
                AUD: 1.4205,
                BGN: 1.9558,
                BRL: 3.4093,
                CAD: 1.4048,
                CHF: 1.0693,
                CNY: 7.3634,
                CZK: 27.021,
                DKK: 7.4367,
                GBP: 0.85143,
                HKD: 8.3006,
                HRK: 7.48,
                HUF: 310.98,
                IDR: 14316.0,
                ILS: 4.0527,
                INR: 72.957,
                JPY: 122.4,
                KRW: 1248.1,
                MXN: 22.476,
                MYR: 4.739,
                NOK: 8.9215,
                NZD: 1.4793,
                PHP: 53.373,
                PLN: 4.3435,
                RON: 4.4943,
                RUB: 64.727,
                SEK: 9.466,
                SGD: 1.5228,
                THB: 37.776,
                TRY: 4.1361,
                USD: 1.07,
                ZAR: 14.31
              }
            }

      """
      @impl unquote(__MODULE__)
      def get_rates do
        UpdateWorker.get_rates(@update_worker)
      end

      @doc """
      Refresh exchange rates

      ### Examples

      iex> #{__MODULE__}.refresh_rates()
      :ok
      """
      @spec refresh_rates() :: :ok | {:error, term}
      def refresh_rates do
        UpdateWorker.refresh_rates(@update_worker)
      end
    end
  end

  alias CurrencyConversion.Rates

  @doc false
  @spec convert(amount :: Money.t(), to_currency :: atom, rates :: Rates.t()) :: Money.t()
  def convert(%Money{amount: 0}, to_currency, _), do: Money.new(0, to_currency)
  def convert(amount = %Money{currency: currency}, currency, _), do: amount

  def convert(%Money{amount: amount, currency: currency}, to_currency, %Rates{
        base: currency,
        rates: rates
      }) do
    Money.new(round(amount * Map.fetch!(rates, to_currency)), to_currency)
  end

  def convert(%Money{amount: amount, currency: currency}, to_currency, %Rates{
        base: to_currency,
        rates: rates
      }) do
    Money.new(round(amount / Map.fetch!(rates, currency)), to_currency)
  end

  def convert(amount, to_currency, rates) do
    convert(convert(amount, rates.base, rates), to_currency, rates)
  end

  @doc false
  @spec get_currencies(rates :: Rates.t()) :: [atom]
  def get_currencies(%Rates{base: base, rates: rates}), do: [base | Map.keys(rates)]
end

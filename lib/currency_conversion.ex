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

  @convert_doc """
  Convert from currency A to B.

  ### Example

      iex> convert(Money.new(7_00, :CHF), :USD)
      %Money{amount: 7_03, currency: :USD}

  """
  @doc @convert_doc
  @callback convert(amount :: Money.t(), to_currency :: atom) :: Money.t()

  @get_currencies_doc """
  Get all currencies

  ### Examples

      iex> get_currencies()
      [:EUR, :CHF, :USD, ...]

  """
  @doc @get_currencies_doc
  @callback get_currencies :: [atom]

  @get_rates_doc """
  Get current exchange rates

  ### Examples

      iex> get_rates()
      %CurrencyConversion.Rates{
          base: :EUR,
          rates: %{
            AUD: 1.4205,
            BGN: 1.9558,
            ...
          }
        }

  """
  @doc @get_rates_doc
  @callback get_rates :: CurrencyConversion.Rates.t()

  @refresh_rates_doc """
  Refresh exchange rates

  ### Examples

      iex> refresh_rates()
      :ok

  """
  @doc @refresh_rates_doc
  @callback refresh_rates :: :ok | {:error, term}

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

      @doc unquote(@convert_doc)
      @impl unquote(__MODULE__)
      def convert(amount, to_currency) do
        unquote(__MODULE__).convert(amount, to_currency, UpdateWorker.get_rates(@update_worker))
      end

      @doc unquote(@get_currencies_doc)
      @impl unquote(__MODULE__)
      def get_currencies do
        unquote(__MODULE__).get_currencies(UpdateWorker.get_rates(@update_worker))
      end

      @doc unquote(@get_rates_doc)
      @impl unquote(__MODULE__)
      def get_rates do
        UpdateWorker.get_rates(@update_worker)
      end

      @doc unquote(@refresh_rates_doc)
      @impl unquote(__MODULE__)
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

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
        config = Application.get_env(@otp_app, __MODULE__)

        Supervisor.init([{UpdateWorker, config ++ [name: @update_worker]}], strategy: :one_for_one)
      end

      @doc """
      Convert from currency A to B.

      ### Example

          iex> #{__MODULE__}.convert(Money.new(7_00, :CHF), :USD)
          %Money{amount: 10_50, currency: :USD}

          iex> #{__MODULE__}.convert(Money.new(7_00, :EUR), :USD)
          %Money{amount: 5_25, currency: :USD}

          iex> #{__MODULE__}.convert(Money.new(7_00, :CHF), :EUR)
          %Money{amount: 14_00, currency: :EUR}

          iex> #{__MODULE__}.convert(Money.new(0, :CHF), :EUR)
          %Money{amount: 0, currency: :EUR}

          iex> #{__MODULE__}.convert(Money.new(7_20, :CHF), :CHF)
          %Money{amount: 7_20, currency: :CHF}

      """
      @impl unquote(__MODULE__)
      def convert(amount, to_currency) do
        unquote(__MODULE__).convert(amount, to_currency, UpdateWorker.get_rates(@update_worker))
      end

      @doc """
      Get all currencies

      ### Examples

          iex> CurrencyConversion.get_currencies()
          [:EUR, :CHF, :USD]

      """
      @impl unquote(__MODULE__)
      def get_currencies do
        unquote(__MODULE__).get_currencies(UpdateWorker.get_rates(@update_worker))
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

defmodule CurrencyConversion.UpdateWorker do
  @moduledoc false

  use GenServer
  alias CurrencyConversion.Rates

  require Logger

  @default_refresh_interval 1000 * 60 * 60 * 24

  @doc """
  Starts the update worker.
  """
  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts, name: Keyword.fetch!(opts, :name))
  end

  @impl GenServer
  def init(opts) do
    table_identifier =
      opts
      |> Keyword.get(:name, __MODULE__)
      |> table_name
      |> :ets.new([:protected, :ordered_set, :named_table])

    opts = Keyword.put(opts, :table_identifier, table_identifier)

    refresh_interval = Keyword.get(opts, :refresh_interval, @default_refresh_interval)

    initial_load =
      case Keyword.fetch(opts, :seed) do
        {:ok, {module, function, arity}} when arity == 1 ->
          Function.capture(module, function, arity)

        {:ok, function} when is_function(function, 1) ->
          function

        :error ->
          &load_from_source/1
      end

    case {refresh(opts, initial_load), refresh_interval} do
      {:ok, :manual} -> {:ok, opts}
      {:ok, _} -> {:ok, opts, refresh_interval}
      {{:error, binary}, _} -> {:stop, {:error, binary}}
    end
  end

  @impl GenServer
  def handle_info(:timeout, opts) do
    refresh_interval = Keyword.get(opts, :refresh_interval, @default_refresh_interval)

    case {refresh(opts), refresh_interval} do
      {:ok, :manual} -> {:noreply, opts}
      {:ok, _} -> {:noreply, opts, refresh_interval}
      {{:error, binary}, _} -> {:stop, {:error, binary}}
    end
  end

  @impl GenServer
  def handle_call(:refresh, _from, opts) do
    opts
    |> Keyword.get(:refresh_interval, @default_refresh_interval)
    |> case do
      :manual -> {:reply, refresh(opts), opts}
      refresh_interval -> {:reply, refresh(opts), opts, refresh_interval}
    end
  end

  @spec refresh_rates(worker_name :: atom()) :: :ok | {:error, term}
  def refresh_rates(worker_name) do
    GenServer.call(worker_name, :refresh)
  end

  defp load_from_source(opts) do
    Keyword.get(opts, :source, CurrencyConversion.Source.ExchangeRatesApi).load(opts)
  end

  @spec refresh(
          opts :: Keyword.t(),
          load_callback :: (Keyword.t() -> {:ok, Rates.t()} | {:error, binary})
        ) :: :ok | {:error, binary}
  defp refresh(opts, load_callback \\ &load_from_source/1) do
    table_identifier = Keyword.fetch!(opts, :table_identifier)

    case load_callback.(opts) do
      {:ok, rates} ->
        Logger.info("Refreshed currency rates.")
        Logger.debug(inspect(rates))

        for entry <- Rates.to_list(rates) do
          :ets.insert(table_identifier, entry)
        end

        :ok

      {:error, error} ->
        Logger.error("An error occured while rereshing currency rates. " <> inspect(error))
        {:error, error}
    end
  end

  @spec get_rates(worker_name :: atom()) :: Rates.t()
  def get_rates(worker_name),
    do:
      worker_name
      |> table_name
      |> :ets.tab2list()
      |> Rates.from_list()

  @spec table_name(worker_name :: atom()) :: atom()
  defp table_name(worker_name), do: Module.concat(worker_name, Table)
end

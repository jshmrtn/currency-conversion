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
    GenServer.start_link(__MODULE__, opts, name: Keyword.get(opts, :name, __MODULE__))
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

    case refresh(opts) do
      :ok -> {:ok, opts, refresh_interval}
      {:error, binary} -> {:stop, {:error, binary}}
    end
  end

  @impl GenServer
  def handle_info(:timeout, opts) do
    refresh_interval = Keyword.get(opts, :refresh_interval, @default_refresh_interval)

    case refresh(opts) do
      :ok -> {:noreply, opts, refresh_interval}
      {:error, binary} -> {:stop, {:error, binary}}
    end
  end

  @spec refresh(opts :: Keyword.t()) :: :ok | {:error, binary}
  defp refresh(opts) do
    table_identifier = Keyword.fetch!(opts, :table_identifier)
    source = Keyword.get(opts, :source, CurrencyConversion.Source.Fixer)

    case source.load() do
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
  def get_rates(worker_name \\ __MODULE__),
    do:
      worker_name
      |> table_name
      |> :ets.tab2list()
      |> Rates.from_list()

  @spec table_name(worker_name :: atom()) :: atom()
  defp table_name(worker_name), do: Module.concat(worker_name, Table)
end

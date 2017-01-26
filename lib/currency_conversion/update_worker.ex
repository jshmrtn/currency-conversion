defmodule CurrencyConversion.UpdateWorker do
  @moduledoc false

  use GenServer
  alias CurrencyConversion.Rates

  require Logger

  @update_worker CurrencyConversion.UpdateWorker

  @doc """
  Starts the update worker.
  """
  def start_link do
    GenServer.start_link(__MODULE__, :ok, [name: @update_worker])
  end

  @spec init(:ok) :: {:ok, Rates.t} | {:stop, any}
  def init(:ok) do
    Process.send_after(self(), :refresh, get_refresh_interval())
    case refresh do
      {:ok, rates} -> {:ok, rates}
      {:error, binary} -> {:stop, {:error, binary}}
    end
  end

  @spec handle_call(:get, any, Rates.t) :: {:reply, Rates.t, Rates.t}
  def handle_call(:get, _options, state) do
    {:reply, state, state}
  end

  @spec handle_info(:refresh, Rates.t) :: {:noreply, Rates.t}
  def handle_info(:refresh, state) do
    Process.send_after(self(), :refresh, get_refresh_interval())
    case refresh() do
      {:ok, rates} -> {:noreply, rates}
      {:error, _} -> {:noreply, state}
    end
  end

  defp refresh do
    case get_source().load() do
      {:ok, rates} ->
        Logger.info "Refreshed currency rates."
        Logger.debug inspect(rates)
        {:ok, rates}
      {:error, error} ->
        Logger.error "An error occured while rereshing currency rates. " <> inspect(error)
        {:error, error}
    end
  end

  @spec get_source() :: atom
  defp get_source, do: Application.get_env(:currency_conversion, :source, CurrencyConversion.Source.Fixer)
  # Default: One Day
  @spec get_refresh_interval() :: integer
  defp get_refresh_interval, do: Application.get_env(:currency_conversion, :refresh_interval, 1000 * 60 * 60 * 24)

  @spec get_rates() :: Rates.t
  def get_rates, do: GenServer.call(@update_worker, :get)
end

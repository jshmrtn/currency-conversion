defmodule CurrencyConversion.Application do
  @moduledoc false

  use Application

  alias CurrencyConversion.UpdateWorker

  @spec start(Application.start_type(), start_args :: term) ::
          {:ok, pid}
          | {:ok, pid, Application.state()}
          | {:error, reason :: term}
  def start(_type, _args) do
    Supervisor.start_link(
      [
        {UpdateWorker, Application.get_all_env(:currency_conversion)}
      ],
      strategy: :one_for_one,
      name: CurrencyConversion.Supervisor
    )
  end
end

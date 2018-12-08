defmodule CurrencyConversion.Application do
  @moduledoc false

  use Application

  @spec start(Application.start_type(), start_args :: term) ::
          {:ok, pid}
          | {:ok, pid, Application.state()}
          | {:error, reason :: term}
  def start(_type, _args) do
    import Supervisor.Spec, warn: false

    children = [
      worker(CurrencyConversion.UpdateWorker, [], restart: :permanent)
    ]

    opts = [strategy: :one_for_one, name: CurrencyConversion.Supervisor]
    Supervisor.start_link(children, opts)
  end
end

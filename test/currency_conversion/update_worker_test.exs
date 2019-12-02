defmodule CurrencyConversion.UpdateWorkerTest do
  use ExUnit.Case, async: false

  alias CurrencyConversion.UpdateWorker

  doctest UpdateWorker

  import Mock

  defmodule Source do
    @moduledoc false

    @behaviour CurrencyConversion.Source

    def load do
      {:ok, %CurrencyConversion.Rates{base: :CHF, rates: %{}}}
    end
  end

  test "initial load called", %{test: test_name} do
    name = Module.concat(__MODULE__, test_name)
    start_supervised!({UpdateWorker, source: Source, name: name})

    assert UpdateWorker.get_rates(name) == %CurrencyConversion.Rates{base: :CHF, rates: %{}}
  end

  test "refresh load called", %{test: test_name} do
    test_pid = self()
    name = Module.concat(__MODULE__, test_name)

    with_mock CurrencyConversion.Source.Test,
      load: fn ->
        send(test_pid, :load)
        {:ok, %CurrencyConversion.Rates{base: :CHF, rates: %{}}}
      end do
      start_supervised!(
        {UpdateWorker,
         source: CurrencyConversion.Source.Test, name: name, refresh_interval: 1_000}
      )

      assert_received :load
      assert_receive :load, 1_100
    end
  end
end

defmodule CurrencyConversion.UpdateWorkerTest do
  @moduledoc false

  use ExUnit.Case, async: true

  alias CurrencyConversion.UpdateWorker

  doctest UpdateWorker

  defmodule Source do
    @moduledoc false

    @behaviour CurrencyConversion.Source

    def load(opts) do
      case Keyword.fetch(opts, :caller_pid) do
        {:ok, pid} -> send(pid, :load)
        _ -> nil
      end

      {:ok, %CurrencyConversion.Rates{base: :CHF, rates: %{}}}
    end
  end

  defmodule FailedSource do
    @moduledoc false

    @behaviour CurrencyConversion.Source

    def load(opts) do
      case Keyword.fetch(opts, :caller_pid) do
        {:ok, pid} -> send(pid, :load)
        _ -> nil
      end

      {:error, "foo"}
    end
  end

  describe "init" do
    test "initial load called", %{test: test_name} do
      name = Module.concat(__MODULE__, test_name)
      start_supervised!({UpdateWorker, source: Source, name: name})

      assert UpdateWorker.get_rates(name) == %CurrencyConversion.Rates{base: :CHF, rates: %{}}
    end

    test "initial load fails", %{test: test_name} do
      name = Module.concat(__MODULE__, test_name)

      {:error, {{:error, "foo"}, _}} =
        start_supervised({UpdateWorker, source: FailedSource, name: name})
    end

    test "refresh load called", %{test: test_name} do
      name = Module.concat(__MODULE__, test_name)

      start_supervised!(
        {UpdateWorker, source: Source, name: name, refresh_interval: 1_000, caller_pid: self()}
      )

      assert_received :load
      assert_receive :load, 1_100
    end

    test "manual refresh_inverval does not refresh", %{test: test_name} do
      name = Module.concat(__MODULE__, test_name)

      start_supervised!(
        {UpdateWorker, source: Source, name: name, refresh_interval: :manual, caller_pid: self()}
      )

      assert_received :load
      refute_receive :load
    end
  end

  describe "refresh_rates/1" do
    setup tags do
      name = Module.concat(__MODULE__, tags[:test])

      start_supervised!({UpdateWorker, [name: name, caller_pid: self()] ++ Enum.to_list(tags)})

      assert_received :load

      {:ok, worker_name: name}
    end

    @tag source: Source, refresh_interval: :manual
    test "ok with manual does not refresh", %{worker_name: worker_name} do
      assert :ok = UpdateWorker.refresh_rates(worker_name)

      assert_received :load
      refute_receive :load
    end

    @tag source: Source, refresh_interval: 100
    test "ok with interval does refresh", %{worker_name: worker_name} do
      assert :ok = UpdateWorker.refresh_rates(worker_name)

      assert_received :load
      assert_receive :load, 110
    end

    # TODO: The following two test can be implemented easily as soon as the
    # `seed` config is implemented
    # @tag source: FailedSource, refresh_interval: :manual
    # test "error with manual does not refresh", %{worker_name: worker_name} do
    #   assert {:error, "foo"} = UpdateWorker.refresh_rates(worker_name)

    #   assert_received :load
    #   refute_receive :load
    # end

    # @tag source: FailedSource, refresh_interval: 100
    # test "error with interval does refresh", %{worker_name: worker_name} do
    #   assert {:error, "foo"} = UpdateWorker.refresh_rates(worker_name)

    #   assert_received :load
    #   assert_receive :load, 110
    # end
  end
end

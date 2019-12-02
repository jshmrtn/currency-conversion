defmodule CurrencyConversion.Source.ExchangeRatesApiTest do
  @moduledoc false

  use ExUnit.Case, async: false

  doctest CurrencyConversion.Source.ExchangeRatesApi, except: [load: 1]

  import CurrencyConversion.Source.ExchangeRatesApi
  import Mock

  @not_200_response :something
  test "load when status is not 200" do
    with_mock HTTPotion, get: fn _url, _query -> @not_200_response end do
      assert load([]) == {:error, "Exchange Rates API unavailable."}
    end
  end

  @invalid_json_response %HTTPotion.Response{body: "not JSON", status_code: 200}
  test "load when JSON is invalid" do
    with_mock HTTPotion, get: fn _url, _query -> @invalid_json_response end do
      assert load([]) == {:error, "JSON decoding of response body failed."}
    end
  end

  @wrong_formatted_json [
    %{"foo" => "bar"},
    %{"base" => "CHF", "rates" => []},
    %{"base" => "CHF", "rates" => %{"foo" => "string"}},
    %{"base" => "CHF", "rates" => %{"foo" => :something}}
  ]
  for response <- @wrong_formatted_json do
    @response response
    test "load when JSON fomat is wrong with " <> inspect(response) do
      with_mock HTTPotion,
        get: fn _url, _query ->
          %HTTPotion.Response{body: Poison.encode!(@response), status_code: 200}
        end do
        assert load([]) == {:error, "Exchange Rates API Schema has changed."}
      end
    end
  end

  @correctly_formatted_json %{"base" => "CHF", "rates" => %{"EUR" => 7.2}}
  test "load correctly" do
    with_mock HTTPotion,
      get: fn _url, _query ->
        %HTTPotion.Response{body: Poison.encode!(@correctly_formatted_json), status_code: 200}
      end do
      assert load([]) == {:ok, %CurrencyConversion.Rates{base: :CHF, rates: %{EUR: 7.2}}}
    end
  end
end

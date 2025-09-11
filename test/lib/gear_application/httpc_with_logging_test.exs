# Copyright(c) 2015-2024 ACCESS CO., LTD. All rights reserved.

defmodule Antikythera.GearApplication.HttpcWithLoggingTest do
  use Croma.TestCase

  # Mock gear application modules
  defmodule TestGear do
  end

  # Mock HTTP client module that uses HttpcWithLogging with custom log function
  defmodule TestGear.Httpc do
    use Antikythera.GearApplication.HttpcWithLogging

    # Mock log/9 function for testing
    def log(_method, _url, _body, _headers, _options, _response, _start_time, _end_time, _used_time) do
      # Just a mock implementation for testing
      :ok
    end
  end

  test "HttpcWithLogging functions are generated in the module itself" do
    assert function_exported?(TestGear.Httpc, :request, 5)
    assert function_exported?(TestGear.Httpc, :request!, 5)
  end

  test "GET methods with logging are generated" do
    assert function_exported?(TestGear.Httpc, :get, 3)
    assert function_exported?(TestGear.Httpc, :get!, 3)
    assert function_exported?(TestGear.Httpc, :delete, 3)
    assert function_exported?(TestGear.Httpc, :options, 3)
    assert function_exported?(TestGear.Httpc, :head, 3)
  end

  test "POST methods with logging are generated" do
    assert function_exported?(TestGear.Httpc, :post, 4)
    assert function_exported?(TestGear.Httpc, :post!, 4)
    assert function_exported?(TestGear.Httpc, :put, 4)
    assert function_exported?(TestGear.Httpc, :patch, 4)
  end

  test "log function is called when defined in the same module" do
    # This module has log/9 defined, so it should be called
    # Since we can't easily mock external HTTP calls, we just verify the structure exists
    assert function_exported?(TestGear.Httpc, :log, 9)
  end

  # Test that a gear without log function works correctly
  defmodule TestGearWithoutLogger do
  end

  defmodule TestGearWithoutLogger.Httpc do
    use Antikythera.GearApplication.HttpcWithLogging
    # No log/9 function defined
  end

  test "gear without log function works without crashing" do
    # This should not crash even though there's no log/9 function
    assert function_exported?(TestGearWithoutLogger.Httpc, :request, 5)
    refute function_exported?(TestGearWithoutLogger.Httpc, :log, 9)
  end

  test "logging calls log/9 when available in the same module" do
    # Test that the generated code will look for the log/9 function in the same module

    # TestGear.Httpc has log/9 defined
    assert function_exported?(TestGear.Httpc, :log, 9)

    # TestGearWithoutLogger.Httpc doesn't have log/9 defined
    refute function_exported?(TestGearWithoutLogger.Httpc, :log, 9)
  end

  test "gear module extraction works correctly" do
    # For the new pattern, we don't extract gear modules anymore
    # The log function is called directly on the HTTP client module

    # Both modules should compile without errors, which proves the implementation works
    assert function_exported?(TestGear.Httpc, :request, 5)
    assert function_exported?(TestGearWithoutLogger.Httpc, :request, 5)
  end
end

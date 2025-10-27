# Copyright(c) 2015-2024 ACCESS CO., LTD. All rights reserved.

defmodule AntikytheraCore.HttpLogger do
  @moduledoc """
  A simple logger that behaves like IO.inspect and sends logs to an HTTP endpoint.

  ## Examples

      # Log a value and return it (like IO.inspect)
      result = HttpLogger.inspect(some_value, label: "Debug")

      # Log a message
      HttpLogger.log("Something happened")
  """

  @default_endpoint "http://localhost:8888"

  @doc """
  Logs a value to the HTTP endpoint and returns the value unchanged, similar to IO.inspect.

  ## Options

    * `:label` - A label to prepend to the log message
    * `:endpoint` - Override the default HTTP endpoint (default: #{@default_endpoint})
    * `:pretty` - Pretty print the value (default: false)

  ## Examples

      iex> HttpLogger.inspect(%{key: "value"}, label: "Debug")
      %{key: "value"}
  """
  def inspect(value, opts \\ []) do
    label = Keyword.get(opts, :label)
    endpoint = Keyword.get(opts, :endpoint, @default_endpoint)
    pretty = Keyword.get(opts, :pretty, false)

    message = format_message(value, label, pretty)
    send_log(endpoint, message)

    value
  end

  @doc """
  Logs a message to the HTTP endpoint.

  ## Options

    * `:endpoint` - Override the default HTTP endpoint (default: #{@default_endpoint})
    * `:level` - Log level (default: "info")

  ## Examples

      iex> HttpLogger.log("Something happened")
      :ok
  """
  def log(message, opts \\ []) when is_binary(message) do
    endpoint = Keyword.get(opts, :endpoint, @default_endpoint)
    level = Keyword.get(opts, :level, "info")

    log_data = %{
      level: level,
      message: message,
      timestamp: DateTime.utc_now() |> DateTime.to_iso8601()
    }

    send_log(endpoint, log_data)
  end

  defp format_message(value, label, pretty) do
    formatted_value =
      if pretty do
        Kernel.inspect(value, pretty: true, limit: :infinity)
      else
        Kernel.inspect(value)
      end

    log_data = %{
      level: "debug",
      value: formatted_value,
      timestamp: DateTime.utc_now() |> DateTime.to_iso8601()
    }

    if label do
      Map.put(log_data, :label, to_string(label))
    else
      log_data
    end
  end

  defp send_log(endpoint, data) do
    json_body = Jason.encode!(data)

    headers = [
      {~c"Content-Type", ~c"application/json"}
    ]

    request = {
      to_charlist(endpoint),
      headers,
      ~c"application/json",
      json_body
    }

    # Use httpc to send the request asynchronously
    # We don't wait for the response to avoid blocking
    Task.start(fn ->
      try do
        :httpc.request(:post, request, [], [])
      rescue
        e ->
          # Silently ignore errors to avoid disrupting the main flow
          _ = e
          :ok
      end
    end)

    :ok
  end
end

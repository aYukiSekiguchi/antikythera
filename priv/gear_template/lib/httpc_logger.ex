defmodule <%= gear_name_camel %>.HttpcLogger do
  @moduledoc """
  Custom HTTP client logging for <%= gear_name_camel %> gear.

  This module is automatically detected by Antikythera when using HttpcWithLogging
  and will be called for each HTTP request made via the logging wrapper.
  """

  def log(method, url, body, headers, options, response, start_time, end_time, used_time) do
    # Log basic request information
    method_str = method |> Atom.to_string() |> String.upcase()
    <%= gear_name_camel %>.Logger.info("HTTP #{method_str} #{url} - #{used_time}ms")

    # Log response status or error
    case response do
      {:ok, %{status: status}} when status >= 200 and status < 300 ->
        <%= gear_name_camel %>.Logger.info("HTTP request succeeded: #{status}")

      {:ok, %{status: status}} when status >= 400 ->
        <%= gear_name_camel %>.Logger.error("HTTP request failed with status: #{status}")

      {:error, reason} ->
        <%= gear_name_camel %>.Logger.error("HTTP request failed: #{inspect(reason)}")

      _ ->
        <%= gear_name_camel %>.Logger.info("HTTP request completed")
    end

    # Optional: Log additional details for debugging
    if Application.get_env(:antikythera, :debug_http_logging, false) do
      <%= gear_name_camel %>.Logger.debug("Request headers: #{inspect(headers)}")
      <%= gear_name_camel %>.Logger.debug("Request options: #{inspect(options)}")

      case body do
        {:json, data} -> <%= gear_name_camel %>.Logger.debug("Request body: #{inspect(data)}")
        body when is_binary(body) and byte_size(body) < 1000 ->
          <%= gear_name_camel %>.Logger.debug("Request body: #{body}")
        _ ->
          :ok  # Don't log large bodies
      end
    end
  end
end

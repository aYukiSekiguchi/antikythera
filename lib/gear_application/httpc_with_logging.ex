# Copyright(c) 2015-2024 ACCESS CO., LTD. All rights reserved.

use Croma

defmodule Antikythera.GearApplication.HttpcWithLogging do
  @moduledoc """
  Helper module to create HTTP client wrapper with logging functionality.

  This module provides a wrapper around `Antikythera.Httpc` that automatically includes
  logging capabilities for HTTP requests. When a gear application creates a dedicated
  HTTP client module that `use`s this module, it generates HTTP client functions that
  automatically log HTTP requests using the gear's configured logging mechanism.

  ## Usage

  Create a dedicated HTTP client module in your gear application:

      defmodule MyGear.Httpc do
        use Antikythera.GearApplication.HttpcWithLogging
      end

  This will add HTTP client functions with automatic logging directly to `MyGear.Httpc`.

  ## Generated Functions

  The module that uses `HttpcWithLogging` will have the same interface as
  `Antikythera.Httpc` but with automatic logging:

  - `request/5` - Make HTTP request with logging
  - `request!/5` - Make HTTP request with logging, raising on error
  - `get/3`, `post/4`, `put/4`, etc.
  - `get!/3`, `post!/4`, `put!/4`, etc.

  ## Example

      # In your gear controller:
      response = MyGear.Httpc.get("https://api.example.com/data")

  This will automatically log the HTTP request using your gear's logging configuration,
  and invoke any custom logging callback defined directly in your HTTP client module
  (if present).

  ## Custom Logging Callback

  To customize HTTP request logging, implement a `log/9` function directly in your HTTP client module:

      defmodule MyGear.Httpc do
        use Antikythera.GearApplication.HttpcWithLogging

        def log(method, url, body, headers, options, response, start_time, end_time, used_time) do
          # Custom logging logic here
          # This will be called for each HTTP request made via this HTTP client
        end
      end

  The callback receives:
  - `method` - HTTP method atom (`:get`, `:post`, etc.)
  - `url` - Request URL string
  - `body` - Request body
  - `headers` - Request headers map
  - `options` - Request options keyword list
  - `response` - Response result (success or error)
  - `start_time` - Request start time
  - `end_time` - Request end time
  - `used_time` - Request duration in milliseconds
  """

  alias Antikythera.{Http, Httpc}
  alias Httpc.{ReqBody, Response}
  alias Croma.Result, as: R

  defmacro __using__(_) do
    # Generate method functions outside of the quote to avoid variable scoping issues
    get_methods = for method <- [:get, :delete, :options, :head] do
      quote do
        defun unquote(method)(
                url :: Antikythera.Url.t(),
                headers :: Http.Headers.t() \\ %{},
                options :: Keyword.t() \\ []
              ) :: R.t(Response.t()) do
          request(unquote(method), url, "", headers, options)
        end

        defun unquote(:"#{method}!")(
                url :: Antikythera.Url.t(),
                headers :: Http.Headers.t() \\ %{},
                options :: Keyword.t() \\ []
              ) :: Response.t() do
          request!(unquote(method), url, "", headers, options)
        end
      end
    end

    body_methods = for method <- [:post, :put, :patch] do
      quote do
        defun unquote(method)(
                url :: Antikythera.Url.t(),
                body :: ReqBody.t(),
                headers :: Http.Headers.t() \\ %{},
                options :: Keyword.t() \\ []
              ) :: R.t(Response.t()) do
          request(unquote(method), url, body, headers, options)
        end

        defun unquote(:"#{method}!")(
                url :: Antikythera.Url.t(),
                body :: ReqBody.t(),
                headers :: Http.Headers.t() \\ %{},
                options :: Keyword.t() \\ []
              ) :: Response.t() do
          request!(unquote(method), url, body, headers, options)
        end
      end
    end

    quote do
      alias Antikythera.{Http, Httpc}
      alias Httpc.{ReqBody, Response}
      alias Croma.Result, as: R

      defun request(
              method :: v[Http.Method.t()],
              url :: v[Antikythera.Url.t()],
              body :: v[ReqBody.t()],
              headers :: v[Http.Headers.t()] \\ %{},
              options :: Keyword.t() \\ []
            ) :: R.t(Response.t()) do
        start_monotonic = System.monotonic_time(:millisecond)
        start_time = Antikythera.Time.now()

        response = Httpc.request(method, url, body, headers, options)

        end_time = Antikythera.Time.now()
        used_time = System.monotonic_time(:millisecond) - start_monotonic

        invoke_gear_logger(
          method,
          url,
          body,
          headers,
          options,
          response,
          start_time,
          end_time,
          used_time
        )

        response
      end

      defun request!(
              method :: v[Http.Method.t()],
              url :: v[Antikythera.Url.t()],
              body :: v[ReqBody.t()],
              headers :: v[Http.Headers.t()] \\ %{},
              options :: Keyword.t() \\ []
            ) :: Response.t() do
        request(method, url, body, headers, options) |> R.get!()
      end

      # Private helper function to invoke gear logger
      defp invoke_gear_logger(
             method,
             url,
             body,
             headers,
             options,
             response,
             start_time,
             end_time,
             used_time
           ) do
        # Check if the calling module defines a log/9 function at runtime
        if function_exported?(__MODULE__, :log, 9) do
          try do
            apply(__MODULE__, :log, [method, url, body, headers, options, response, start_time, end_time, used_time])
          rescue
            _ ->
              :ok
          end
        end

        :ok
      end

      # Insert generated GET, DELETE, OPTIONS, HEAD methods
      unquote_splicing(get_methods)

      # Insert generated POST, PUT, PATCH methods
      unquote_splicing(body_methods)
    end
  end
end

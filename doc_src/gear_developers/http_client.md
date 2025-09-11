# HTTP Client

Antikythera provides a powerful HTTP client library through `Antikythera.Httpc` for making external HTTP requests from your gear. For automatic logging of HTTP requests, you can use the `HttpcWithLogging` module.

## Basic Usage

### Using Antikythera.Httpc Directly

```elixir
alias Antikythera.Httpc

# GET request
{:ok, response} = Httpc.get("https://api.example.com/data")

# POST request with JSON body
{:ok, response} = Httpc.post("https://api.example.com/data", 
  {:json, %{name: "example"}}, 
  %{"authorization" => "Bearer token"}
)

# With options
{:ok, response} = Httpc.get("https://api.example.com/data", 
  %{}, 
  [timeout: 10_000, recv_timeout: 5_000]
)
```

### Using HttpcWithLogging

For better observability, you can use `HttpcWithLogging` which automatically logs all HTTP requests:

```elixir
defmodule MyGear do
  use Antikythera.GearApplication
  use Antikythera.GearApplication.HttpcWithLogging
  
  # ... other gear code
end
```

Then in your controllers:

```elixir
defmodule MyGear.Controller.Api do
  use Antikythera.Controller

  def fetch_data(conn) do
    # This will automatically log the HTTP request
    case MyGear.HttpcWithLogging.get("https://api.example.com/data") do
      {:ok, response} ->
        Conn.json(conn, 200, response.body)
      {:error, reason} ->
        Conn.json(conn, 500, %{error: "Failed to fetch data"})
    end
  end
end
```

## Available Methods

Both `Httpc` and `HttpcWithLogging` provide the following HTTP methods:

### Methods without request body
- `get/3`, `get!/3`
- `delete/3`, `delete!/3` 
- `options/3`, `options!/3`
- `head/3`, `head!/3`

### Methods with request body
- `post/4`, `post!/4`
- `put/4`, `put!/4`
- `patch/4`, `patch!/4`

### Generic request method
- `request/5`, `request!/5`

The `!` versions raise an exception on error, while the regular versions return `{:ok, response}` or `{:error, reason}`.

## Request Body Formats

You can send different types of request bodies:

```elixir
# Raw binary data
Httpc.post(url, "raw data", headers)

# Form data
Httpc.post(url, {:form, [{"name", "value"}, {"email", "test@example.com"}]}, headers)

# JSON data (automatically sets content-type header)
Httpc.post(url, {:json, %{name: "value", email: "test@example.com"}}, headers)

# File upload
Httpc.post(url, {:file, "/path/to/file.txt"}, headers)
```

## Request Options

Common options include:

- `:timeout` - Connection timeout in milliseconds (default: 8000)
- `:recv_timeout` - Response timeout in milliseconds (default: 5000) 
- `:max_body` - Maximum response body size (default: 10MB)
- `:params` - Query parameters to append to URL
- `:basic_auth` - `{username, password}` for HTTP basic auth
- `:ssl` - SSL options for HTTPS requests
- `:skip_ssl_verification` - Skip SSL certificate verification (default: false)

Example:

```elixir
options = [
  timeout: 15_000,
  recv_timeout: 10_000,
  max_body: 50 * 1024 * 1024,  # 50MB
  params: [{"page", "1"}, {"limit", "100"}],
  basic_auth: {"username", "password"},
  skip_ssl_verification: true
]

{:ok, response} = Httpc.get("https://api.example.com/data", %{}, options)
```

## Response Structure

The response is an `Antikythera.Httpc.Response` struct containing:

- `status` - HTTP status code (integer)
- `body` - Response body (binary)
- `headers` - Response headers (map with lowercase keys)
- `cookies` - Set-Cookie headers parsed into a map

```elixir
{:ok, %Antikythera.Httpc.Response{
  status: 200,
  body: "response body",
  headers: %{"content-type" => "application/json"},
  cookies: %{}
}} = Httpc.get("https://api.example.com")
```

## Custom Logging

When using `HttpcWithLogging`, you can implement custom logging by creating an `HttpcLogger` module in your gear:

```elixir
defmodule MyGear.HttpcLogger do
  def log(method, url, body, headers, options, response, start_time, end_time, used_time) do
    # Custom logging logic
    MyGear.Logger.info("HTTP #{method |> Atom.to_string() |> String.upcase()} #{url} - #{used_time}ms")
    
    case response do
      {:ok, %{status: status}} ->
        MyGear.Logger.info("Response: #{status}")
      {:error, reason} ->
        MyGear.Logger.error("Request failed: #{inspect(reason)}")
    end
  end
end
```

The log callback receives:
- `method` - HTTP method atom (`:get`, `:post`, etc.)
- `url` - Request URL
- `body` - Request body
- `headers` - Request headers map
- `options` - Request options
- `response` - Response result (`{:ok, response}` or `{:error, reason}`)
- `start_time` - Request start time (`Antikythera.Time.t`)
- `end_time` - Request end time (`Antikythera.Time.t`)
- `used_time` - Request duration in milliseconds

## Best Practices

1. **Use timeouts**: Always set appropriate timeout values for external requests
2. **Handle errors gracefully**: Network requests can fail, always handle error cases
3. **Use logging**: Enable request logging for better observability
4. **Limit response sizes**: Set `max_body` option to prevent memory issues
5. **Connection pooling**: Httpc automatically manages HTTP connections
6. **SSL verification**: Don't skip SSL verification in production

## Error Handling

Common error reasons include:

- `:timeout` - Connection or receive timeout
- `:nxdomain` - Domain name resolution failed
- `:econnrefused` - Connection refused
- `:response_too_large` - Response body exceeds max_body limit

```elixir
case MyGear.HttpcWithLogging.get(url) do
  {:ok, response} ->
    # Success case
    handle_success(response)
    
  {:error, :timeout} ->
    # Timeout occurred
    handle_timeout()
    
  {:error, :nxdomain} ->
    # DNS resolution failed
    handle_dns_error()
    
  {:error, reason} ->
    # Other error
    handle_generic_error(reason)
end
```

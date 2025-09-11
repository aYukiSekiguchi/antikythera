defmodule <%= gear_name_camel %>.Controller.HttpExample do
  use Antikythera.Controller

  def external_api(conn) do
    # Example using the gear's Httpc module with logging
    case <%= gear_name_camel %>.Httpc.get("https://jsonplaceholder.typicode.com/posts/1") do
      {:ok, response} ->
        case Jason.decode(response.body) do
          {:ok, data} ->
            Conn.json(conn, 200, data)
          {:error, _} ->
            Conn.json(conn, 500, %{error: "Failed to decode JSON response"})
        end

      {:error, reason} ->
        Conn.json(conn, 500, %{error: "External API request failed", reason: inspect(reason)})
    end
  end

  def create_post(conn) do
    # Example POST request with JSON body
    post_data = %{
      title: Conn.get_req_param(conn, "title", "Default Title"),
      body: Conn.get_req_param(conn, "body", "Default Body"),
      userId: 1
    }

    case <%= gear_name_camel %>.Httpc.post(
      "https://jsonplaceholder.typicode.com/posts",
      {:json, post_data},
      %{"content-type" => "application/json"}
    ) do
      {:ok, response} when response.status in 200..299 ->
        case Jason.decode(response.body) do
          {:ok, created_post} ->
            Conn.json(conn, 201, created_post)
          {:error, _} ->
            Conn.json(conn, 500, %{error: "Failed to decode response"})
        end

      {:ok, response} ->
        Conn.json(conn, response.status, %{error: "API returned error", body: response.body})

      {:error, reason} ->
        Conn.json(conn, 500, %{error: "Request failed", reason: inspect(reason)})
    end
  end
end

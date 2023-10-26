defmodule DisplayGeodataApi.RateLimiter do
  @moduledoc """
  Middleware for rate limiting.
  """

  import Plug.Conn

  def init(opts), do: opts

  def call(conn, _opts) do
    token = Map.get(conn.query_params, "access_token")

    case rate_limit(token) do
      {:ok, _} ->
        conn

      {:error, _} ->
        conn
        |> send_resp(429, "Too many requests (max 1 request per 10 seconds per token)")
        |> halt()
    end
  end

  defp rate_limit(token) do
    # Utilisation directe de ExRated.check_rate/3
    # 1 request per 10 seconds
    ExRated.check_rate("rate_limiter:#{token}", 10_000, 1)
  end
end

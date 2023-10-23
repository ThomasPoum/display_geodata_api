defmodule DisplayGeodataApi.Tokens.TokenAuth do
  import Plug.Conn
  alias DisplayGeodataApi.Tokens.Tokens

  def init(opts), do: opts

  def call(conn, _opts) do
    token = Map.get(conn.query_params, "access_token")

    if token != nil && Tokens.token_exists?(token) do
      assign(conn, :access_token, token)
    else
      conn
      |> send_resp(401, Jason.encode!("Unauthorized. Use your token. Ask one if you don't have one at thomas.poumarede+display_geodata_api_token@gmail.com"))
      |> halt()
    end
  end
end

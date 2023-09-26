defmodule DisplayGeodataApi.Repo do
  use Ecto.Repo,
    otp_app: :display_geodata_api,
    adapter: Ecto.Adapters.Postgres
end

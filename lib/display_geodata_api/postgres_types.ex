defmodule DisplayGeodataApi.PostgresTypes do
  Postgrex.Types.define(MyApp.PostgresTypes,
  [Geo.PostGIS.Extension] ++ Ecto.Adapters.Postgres.extensions(),
  json: Poison)
end

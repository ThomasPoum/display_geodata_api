defmodule DisplayGeodataApi.Repo.Migrations.AddGeohashToCarreau do
  use Ecto.Migration

  def up do
    alter table(:carreaux) do
      add :geohash, :string
    end

    flush()

    execute "UPDATE carreaux SET geohash = ST_GeoHash(coordinates);"
    execute "CREATE INDEX carreaux_geohash_idx ON carreaux USING btree(geohash);"
    execute "CLUSTER carreaux USING carreaux_geohash_idx;"
  end

  def down do
    execute "DROP INDEX carreaux_geohash_idx;"
    alter table(:carreaux) do
      remove :geohash
    end
  end
end

defmodule DisplayGeodataApi.Repo.Migrations.AddCoordinatesToCarreaux do
  use Ecto.Migration

  def up do
    execute "CREATE EXTENSION IF NOT EXISTS postgis;"
    alter table(:carreaux) do
      add :coordinates, :geometry, srid: 4326  # Le SRID est optionnel
    end
  end

  def down do
    # execute "DROP EXTENSION IF EXISTS postgis;"

    alter table(:carreaux) do
      remove :coordinates
    end
  end
end

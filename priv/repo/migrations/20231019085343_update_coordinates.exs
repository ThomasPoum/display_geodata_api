defmodule DisplayGeodataApi.Repo.Migrations.UpdateCoordinates do
  use Ecto.Migration

  def up do
    execute("""
    UPDATE carreaux
    SET coordinates = ST_SetSRID(ST_MakePoint(longitude, latitude), 4326)
    WHERE longitude IS NOT NULL AND latitude IS NOT NULL;
    """)
  end

  def down do
    execute("""
    -- Vous pouvez mettre ici le code pour annuler la migration si nécessaire
    """)
  end
end

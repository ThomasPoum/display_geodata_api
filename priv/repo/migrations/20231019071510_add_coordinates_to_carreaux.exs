defmodule DisplayGeodataApi.Repo.Migrations.AddCoordinatesToCarreaux do
  use Ecto.Migration

  def change do
    alter table(:carreaux) do
      add :coordinates, :geometry, srid: 4326  # Le SRID est optionnel
    end
  end
end

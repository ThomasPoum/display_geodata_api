defmodule DisplayGeodataApi.Repo.Migrations.ChangeColumnsNames do
  use Ecto.Migration

  def change do
    # Rename longitude to temp_longitude
    rename table(:carreaux), :longitude, to: :temp_longitude

    # Rename latitude to longitude
    rename table(:carreaux), :latitude, to: :longitude

    # Rename temp_longitude to latitude
    rename table(:carreaux), :temp_longitude, to: :latitude
  end
end

defmodule DisplayGeodataApi.Repo.Migrations.CreateIndexes do
  use Ecto.Migration

  def change do
    create(index(:carreaux, [:latitude]))
    create(index(:carreaux, [:longitude]))
  end
end

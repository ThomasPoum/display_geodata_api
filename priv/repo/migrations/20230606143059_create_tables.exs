defmodule DisplayGeodataApi.Repo.Migrations.CreateTables do
  use Ecto.Migration

  def change do
    create_if_not_exists table(:carreaux) do
      add(:idINSPIRE, :string)
      add(:id_carr1km, :string)
      add(:i_est_cr, :integer)
      add(:id_carr_n, :string)
      add(:groupe, :integer)
      add(:depcom, :integer)
      add(:i_pauv, :integer)
      add(:id_car2010, :string)
      add(:ind, :float)
      add(:men, :float)
      add(:men_pauv, :float)
      add(:men_1ind, :float)
      add(:men_5ind, :float)
      add(:men_prop, :float)
      add(:men_fmp, :float)
      add(:ind_snv, :float)
      add(:men_surf, :float)
      add(:men_coll, :float)
      add(:men_mais, :float)
      add(:log_av45, :float)
      add(:log_45_70, :float)
      add(:log_70_90, :float)
      add(:log_ap90, :float)
      add(:log_inc, :float)
      add(:log_soc, :float)
      add(:ind_0_3, :float)
      add(:ind_4_5, :float)
      add(:ind_6_10, :float)
      add(:ind_11_17, :float)
      add(:ind_18_24, :float)
      add(:ind_25_39, :float)
      add(:ind_40_54, :float)
      add(:ind_55_64, :float)
      add(:ind_65_79, :float)
      add(:ind_80p, :float)
      add(:ind_inc, :float)
      add(:i_est_1km, :integer)
      add(:longitude, :float)
      add(:latitude, :float)

      timestamps()
    end

    create_if_not_exists table(:tokens) do
      add(:token, :string)

      timestamps()
    end
  end
end

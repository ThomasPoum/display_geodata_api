defmodule DisplayGeodataApi.Schemas.Carreau do

  use Ecto.Schema

  import Ecto.Changeset

  @derive {Jason.Encoder, only: [:idINSPIRE]}

  schema "carreaux" do

    field :idINSPIRE, :string
    field :id_carr1km, :string
    field :i_est_cr, :integer
    field :id_carr_n, :string
    field :groupe, :integer
    field :depcom, :integer
    field :i_pauv, :integer
    field :id_car2010, :string
    field :ind, :float
    field :men, :float
    field :men_pauv, :float
    field :men_1ind, :float
    field :men_5ind, :float
    field :men_prop, :float
    field :men_fmp, :float
    field :ind_snv, :float
    field :men_surf, :float
    field :men_coll, :float
    field :men_mais, :float
    field :log_av45, :float
    field :log_45_70, :float
    field :log_70_90, :float
    field :log_ap90, :float
    field :log_inc, :float
    field :log_soc, :float
    field :ind_0_3, :float
    field :ind_4_5, :float
    field :ind_6_10, :float
    field :ind_11_17, :float
    field :ind_18_24, :float
    field :ind_25_39, :float
    field :ind_40_54, :float
    field :ind_55_64, :float
    field :ind_65_79, :float
    field :ind_80p, :float
    field :ind_inc, :float
    field :i_est_1km, :integer
    field :longitude, :float
    field :latitude, :float
    field :coordinates, Geo.PostGIS.Geometry

    timestamps()

  end

  def changeset(struct, params \\ %{}) do
    struct
    |> cast(params, [:idINSPIRE, :id_carr1km, :i_est_cr, :id_carr_n, :groupe, :depcom, :i_pauv, :id_car2010, :ind, :men, :men_pauv, :men_1ind, :men_5ind, :men_prop, :men_fmp, :ind_snv, :men_surf, :men_coll, :men_mais, :log_av45, :log_45_70, :log_70_90, :log_ap90, :log_inc, :log_soc, :ind_0_3, :ind_4_5, :ind_6_10, :ind_11_17, :ind_18_24, :ind_25_39, :ind_40_54, :ind_55_64, :ind_65_79, :ind_80p, :ind_inc, :i_est_1km, :longitude, :latitude, :coordinates])

  end

end

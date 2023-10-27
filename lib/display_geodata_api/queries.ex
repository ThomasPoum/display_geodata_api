defmodule DisplayGeodataApi.Queries do
  alias DisplayGeodataApi.Carreaux.Carreaux

  @props_keys [
    "ind",
    "men",
    "men_pauv",
    "men_1ind",
    "men_5ind",
    "men_prop",
    "men_fmp",
    "ind_snv",
    "men_surf",
    "men_coll",
    "men_mais",
    "log_av45",
    "log_45_70",
    "log_70_90",
    "log_ap90",
    "log_inc",
    "log_soc",
    "ind_0_3",
    "ind_4_5",
    "ind_6_10",
    "ind_11_17",
    "ind_18_24",
    "ind_25_39",
    "ind_40_54",
    "ind_55_64",
    "ind_65_79",
    "ind_80p",
    "ind_inc",
    "i_est_1km"
  ]

  def check_query(conn) do
    coords = Map.get(conn.query_params, "coords")
    radius = Map.get(conn.query_params, "radius")

    # list_of_props_keys =
    #   conn.query_params
    #   |> Map.get("data")
    #   |> String.split(";")

    {state_props, msg} =
      case Map.get(conn.query_params, "data") do
        nil ->
          {false, "Pas de paramètres dans l'url"}

        _ ->
          conn.query_params
          |> Map.get("data")
          |> String.split(";")
          |> check_props_keys()
      end

    # Vérifier si les paramètres sont présents
    unless is_binary(coords) and is_binary(radius) do
      {:error, "Les paramètres de requête sont invalides."}
    else
      unless state_props do
        {:error,
         "Au moins un des paramètres de données demandées n'est pas correct. #{msg}"}
      else
        # Vérifier si les paramètres ont le bon format
        coords = String.split(coords, ";")

        result =
          Enum.reduce(coords, {:ok, conn.query_params}, fn coord, acc ->
            case acc do
              # Si une erreur a déjà été trouvée, retournez-la.
              {:error, _} = error ->
                error

              _ ->
                [longitude, latitude] = String.split(coord, ",")

                unless parse_float(longitude) != nil and parse_float(latitude) != nil and
                         parse_float(radius) != nil do
                  {:error, "Les paramètres de requête doivent être des valeurs numériques."}
                else
                  # Vérifier si les paramètres sont dans la plage attendue, le cas échéant
                  unless parse_float(longitude) >= -180.0 and parse_float(longitude) <= 180.0 and
                           parse_float(latitude) >= -90.0 and parse_float(latitude) <= 90.0 do
                    {:error, "Les coordonnées doivent être valides."}
                  else
                    # Vérifier si le radius est dans la plage attendue
                    unless parse_float(radius) <= 1.5 do
                      {:error, "Le radius ne doit pas être supérieur à 1.5"}
                    else
                      {max_distance, _barycentre_latitude, _barycentre_longitude} =
                        Carreaux.max_distance_between_coords(coords)

                      unless max_distance <= 50.0 do
                        {:error,
                         "La distance entre le barycentre des points et le point le plus éloigné ne doit pas être supérieur à 50 kilomètres."}
                      else
                        # Autres vérifications de validité des paramètres de requête
                      end
                    end
                  end
                end
            end
          end)

        # Si toutes les vérifications passent, retourner :ok
        if result == nil, do: {:ok, conn.query_params}, else: result
      end
    end
  end

  def check_temp_query(conn) do
    {:ok, conn.query_params}
  end

  def check_props_keys(list_of_props_keys) do
    list_check =
      list_of_props_keys
      |> Enum.map(fn x -> Enum.member?(@props_keys, String.downcase(x)) end)

    case Enum.member?(list_check, false) do
      true ->
        index = Enum.find_index(list_check, fn x -> x == false end)
        {false, "->#{Enum.at(list_of_props_keys, index)}<- n'existe pas, voir dans la liste suivante : #{Enum.reduce(@props_keys, "", fn x, acc -> acc <> "#{x}, " end)}et voir la nomenclature sur le site de l'INSEE (https://www.insee.fr/fr/statistiques/4176290#dictionnaire) pour plus de détails sur chacune des variables disponibles"}

      false ->
        {true, "everything is ok!"}
    end
  end

  defp parse_float(value) do
    case Float.parse(value) do
      {float, _} -> float
      _ -> nil
    end
  end
end

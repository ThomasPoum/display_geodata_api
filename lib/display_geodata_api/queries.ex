defmodule DisplayGeodataApi.Queries do
  def check_query(conn) do
    longitude = Map.get(conn.query_params, "longitude")
    latitude = Map.get(conn.query_params, "latitude")
    radius = Map.get(conn.query_params, "radius")

    # Vérifier si les paramètres sont présents
    unless is_binary(longitude) and is_binary(latitude) and is_binary(radius) do
      {:error, "Les paramètres de requête sont invalides."}
    else
      # Vérifier si les paramètres ont le bon format
      unless parse_float(longitude) != nil and parse_float(latitude) != nil and
               parse_float(radius) != nil do
        {:error, "Les paramètres de requête doivent être des valeurs numériques."}
      else
        # Vérifier si les paramètres sont dans la plage attendue, le cas échéant
        unless parse_float(longitude) >= -180.0 and parse_float(longitude) <= 180.0 do
          {:error, "La longitude doit être comprise entre -180 et 180."}
        else
          # Autres vérifications de validité des paramètres de requête

          # Si toutes les vérifications passent, retourner :ok
          {:ok, conn.query_params}
        end
      end
    end
  end

  def new_check_query(conn) do
    coords = Map.get(conn.query_params, "coords")
    radius = Map.get(conn.query_params, "radius")

    # Vérifier si les paramètres sont présents
    unless is_binary(coords) and is_binary(radius) do
      {:error, "Les paramètres de requête sont invalides."}
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
                  # Autres vérifications de validité des paramètres de requête
                end
              end
          end
        end)

      # Si toutes les vérifications passent, retourner :ok
      if result == nil, do: {:ok, conn.query_params}, else: result
    end
  end

  def check_temp_query(conn) do
    {:ok, conn.query_params}
  end

  defp parse_float(value) do
    case Float.parse(value) do
      {float, _} -> float
      _ -> nil
    end
  end
end

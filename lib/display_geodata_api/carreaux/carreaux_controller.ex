defmodule DisplayGeodataApi.CarreauxController do
  import Plug.Conn
  alias DisplayGeodataApi.Carreaux.Carreaux
  # alias GeodataApi.Tokens.Tokens
  alias DisplayGeodataApi.Queries

  def init(opts), do: opts

  def call(conn, _opts) do
    search_optimized(conn)
  end

  def search_optimized(conn) do
    case Queries.check_query(conn) do
      {:ok, query_params} ->
        # Récupérer les paramètres de la requête
        coords = Map.get(query_params, "coords")
        radius = Map.get(query_params, "radius", 0.0) |> String.to_float()

        # Diviser la chaîne de coordonnées en plusieurs paires de longitude et latitude
        coords = String.split(coords, ";")

        {max_distance, barycentre_latitude, barycentre_longitude} =
          Carreaux.max_distance_between_coords(coords)

        # Etape 3: Utilisation du nouveau rayon
        # ajout de 300m
        new_radius = max_distance + 0.3

        # Créer un MapSet pour stocker des carreaux uniques et un map pour les totaux
        carreaux_mapset = MapSet.new()
        age_totals = %{"ind_0_17" => 0, "ind_18_24" => 0, "ind_25_64" => 0, "ind_65_80p" => 0}

        filtered_carreaux =
          Carreaux.get_filtered_carreaux(barycentre_latitude, barycentre_longitude, new_radius)

        # Appeler la fonction du contexte Carreaux pour chaque paire de coordonnées
        {carreaux_mapset, age_totals} =
          context_carreaux(coords, carreaux_mapset, age_totals, radius, filtered_carreaux)

        # Convertir le MapSet en liste pour le résultat
        result = MapSet.to_list(carreaux_mapset)

        conn
        |> put_resp_content_type("application/json")
        |> put_resp_header("access-control-allow-origin", "*")
        |> send_resp(200, Jason.encode!(Map.merge(%{result: result}, age_totals)))

      {:error, error_message} ->
        coords = Map.get(conn.query_params, "coords", :not_found)

        case coords do
          :not_found ->
            conn
            |> put_resp_content_type("application/json")
            |> put_resp_header("access-control-allow-origin", "*")
            |> send_resp(400, Jason.encode!(%{error: "pas de query présente dans l url"}))
            |> halt()

          _ ->
            conn
            |> put_resp_content_type("application/json")
            |> put_resp_header("access-control-allow-origin", "*")
            |> send_resp(400, Jason.encode!(%{error: error_message}))
            |> halt()
        end
    end
  end

  def calculate_distance(latitude1, longitude1, latitude2, longitude2) do
    # Rayon de la Terre en mètres
    # en mètres
    earth_radius = 6_371_000.0

    # Convertir les latitudes et longitudes en radians
    lat1 = latitude1 * :math.pi() / 180
    lon1 = longitude1 * :math.pi() / 180
    lat2 = latitude2 * :math.pi() / 180
    lon2 = longitude2 * :math.pi() / 180

    # Appliquer la formule de Haversine
    dlat = lat2 - lat1
    dlon = lon2 - lon1

    a =
      :math.sin(dlat / 2) * :math.sin(dlat / 2) +
        :math.cos(lat1) * :math.cos(lat2) *
          :math.sin(dlon / 2) * :math.sin(dlon / 2)

    c = 2 * :math.atan2(:math.sqrt(a), :math.sqrt(1 - a))

    # Calculer la distance en mètres
    distance = earth_radius * c

    # Convertir en kilomètres
    distance_km = distance / 1000.0

    distance_km
  end

  @doc """
  Calculates and collects information about "carreaux" (tiles) that are within a specified radius from given coordinates, and aggregates age group data from these tiles.

  ## Parameters

  - `coords`: A list of strings representing coordinates where each coordinate is formatted as "longitude,latitude".
  - `carreaux_mapset`: A mapset to accumulate unique tiles.
  - `age_totals`: A map to accumulate age group data.
  - `radius`: The radius within which to search for tiles.
  - `filtered_carreaux`: A list of pre-filtered tiles to search within.

  ## Returns

  A tuple containing two elements:
  - A MapSet of unique tiles found within the specified radius from the given coordinates.
  - A map with aggregated age group data from these tiles.

  ## Examples

  ```elixir
  iex> coords = ["2.2945,48.8584", "2.2901,48.8637"]
  iex> carreaux_mapset = MapSet.new()
  iex> age_totals = %{
  ...>   "ind_0_17" => 0,
  ...>   "ind_18_24" => 0,
  ...>   "ind_25_64" => 0,
  ...>   "ind_65_80p" => 0
  ...> }
  iex> radius = 5
  iex> filtered_carreaux = Carreaux.load_pre_filtered_tiles()
  iex> {updated_carreaux_mapset, updated_age_totals} = context_carreaux(
  ...>   coords,
  ...>   carreaux_mapset,
  ...>   age_totals,
  ...>   radius,
  ...>   filtered_carreaux
  ...> )
  """
  def context_carreaux(coords, carreaux_mapset, age_totals, radius, filtered_carreaux) do
    Enum.reduce(coords, {carreaux_mapset, age_totals}, fn coord, {acc_set, acc_totals} ->
      [longitude, latitude] = String.split(coord, ",")
      longitude = String.to_float(longitude)
      latitude = String.to_float(latitude)

      carreaux =
        Carreaux.get_carreaux_in_radius_5(latitude, longitude, radius, filtered_carreaux)
        |> Enum.map(&Carreaux.create_feature_2/1)

      acc_set = Enum.reduce(carreaux, acc_set, &MapSet.put(&2, &1))

      acc_totals =
        Enum.reduce(carreaux, acc_totals, fn carreau, acc ->
          Map.update(
            acc,
            "ind_0_17",
            carreau["properties"]["ind_0_17"],
            &(&1 + carreau["properties"]["ind_0_17"])
          )
          |> Map.update(
            "ind_18_24",
            carreau["properties"]["ind_18_24"],
            &(&1 + carreau["properties"]["ind_18_24"])
          )
          |> Map.update(
            "ind_25_64",
            carreau["properties"]["ind_25_64"],
            &(&1 + carreau["properties"]["ind_25_64"])
          )
          |> Map.update(
            "ind_65_80p",
            carreau["properties"]["ind_65_80p"],
            &(&1 + carreau["properties"]["ind_65_80p"])
          )
        end)

      {acc_set, acc_totals}
    end)
  end
end

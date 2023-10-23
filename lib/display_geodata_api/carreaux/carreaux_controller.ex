defmodule DisplayGeodataApi.CarreauxController do
  import Plug.Conn
  alias DisplayGeodataApi.Carreaux.Carreaux
  # alias GeodataApi.Tokens.Tokens
  alias DisplayGeodataApi.Queries

  def init(opts), do: opts

  def call(conn, _opts) do
    # new_new_new_search(conn)
    search_optimized(conn)
    # conn
  end

  def search(conn) do
    case Queries.check_query(conn) do
      {:ok, query_params} ->
        # Récupérer les paramètres de la requête
        longitude = Map.get(query_params, "longitude", 0.0) |> String.to_float()
        latitude = Map.get(query_params, "latitude", 0.0) |> String.to_float()
        radius = Map.get(query_params, "radius", 0.0) |> String.to_float()

        # Appeler la fonction du contexte Carreaux pour récupérer les carreaux dans le rayon
        carreaux =
          Carreaux.get_carreaux_in_radius_2(latitude, longitude, radius)
          |> Enum.map(fn x ->
            Carreaux.create_feature(x)
          end)
          |> IO.inspect()

        # Exemple de résultat
        result = %{result: carreaux}

        conn
        |> put_resp_content_type("application/json")
        |> send_resp(200, Jason.encode!(result))

      {:error, error_message} ->
        conn
        |> put_resp_content_type("application/json")
        |> send_resp(400, Jason.encode!(%{error: error_message}))
        |> halt()
    end
  end

  def new_search(conn) do
    case Queries.new_check_query(conn) do
      {:ok, query_params} ->
        # Récupérer les paramètres de la requête
        coords = Map.get(query_params, "coords")
        radius = Map.get(query_params, "radius", 0.0) |> String.to_float()

        # Diviser la chaîne de coordonnées en plusieurs paires de longitude et latitude
        coords = String.split(coords, ";")

        # Appeler la fonction du contexte Carreaux pour chaque paire de coordonnées
        result =
          Enum.map(coords, fn coord ->
            [longitude, latitude] = String.split(coord, ",")
            longitude = String.to_float(longitude)
            latitude = String.to_float(latitude)

            carreaux =
              Carreaux.get_carreaux_in_radius_2(latitude, longitude, radius)
              |> Enum.map(&Carreaux.create_feature/1)

            %{longitude: longitude, latitude: latitude, carreaux: carreaux}
          end)

        conn
        |> put_resp_content_type("application/json")
        |> send_resp(200, Jason.encode!(%{result: result}))

      {:error, error_message} ->
        conn
        |> put_resp_content_type("application/json")
        |> send_resp(400, Jason.encode!(%{error: error_message}))
        |> halt()
    end
  end

  def new_new_search(conn) do
    case Queries.new_check_query(conn) do
      {:ok, query_params} ->
        # Récupérer les paramètres de la requête
        coords = Map.get(query_params, "coords")
        radius = Map.get(query_params, "radius", 0.0) |> String.to_float()

        # Diviser la chaîne de coordonnées en plusieurs paires de longitude et latitude
        coords = String.split(coords, ";")

        # Créer un MapSet pour stocker des carreaux uniques
        carreaux_mapset = MapSet.new()

        # Appeler la fonction du contexte Carreaux pour chaque paire de coordonnées
        carreaux_mapset =
          Enum.reduce(coords, carreaux_mapset, fn coord, acc ->
            [longitude, latitude] = String.split(coord, ",")
            longitude = String.to_float(longitude)
            latitude = String.to_float(latitude)

            carreaux =
              Carreaux.get_carreaux_in_radius_2(latitude, longitude, radius)
              |> Enum.map(&Carreaux.create_feature/1)

            Enum.reduce(carreaux, acc, &MapSet.put(&2, &1))
          end)

        # Convertir le MapSet en liste pour le résultat
        result = MapSet.to_list(carreaux_mapset)

        conn
        |> put_resp_content_type("application/json")
        |> send_resp(200, Jason.encode!(%{result: result}))

      {:error, error_message} ->
        conn
        |> put_resp_content_type("application/json")
        |> send_resp(400, Jason.encode!(%{error: error_message}))
        |> halt()
    end
  end

  def new_new_new_search(conn) do
    IO.inspect("OOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOO")

    case Queries.new_check_query(conn) do
      {:ok, query_params} ->
        # Récupérer les paramètres de la requête
        coords = Map.get(query_params, "coords")
        radius = Map.get(query_params, "radius", 0.0) |> String.to_float()

        # Diviser la chaîne de coordonnées en plusieurs paires de longitude et latitude
        coords = String.split(coords, ";")

        # Créer un MapSet pour stocker des carreaux uniques et un map pour les totaux
        carreaux_mapset = MapSet.new()
        age_totals = %{"ind_0_17" => 0, "ind_18_24" => 0, "ind_25_64" => 0, "ind_65_80p" => 0}

        # Appeler la fonction du contexte Carreaux pour chaque paire de coordonnées
        {carreaux_mapset, age_totals} =
          Enum.reduce(coords, {carreaux_mapset, age_totals}, fn coord, {acc_set, acc_totals} ->
            [longitude, latitude] = String.split(coord, ",")
            longitude = String.to_float(longitude)
            latitude = String.to_float(latitude)

            carreaux =
              Carreaux.get_carreaux_in_radius_4(latitude, longitude, radius)
              |> Enum.map(&Carreaux.create_feature/1)

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

  def search_optimized(conn) do
    case Queries.new_check_query(conn) do
      {:ok, query_params} ->
        # Récupérer les paramètres de la requête
        coords = Map.get(query_params, "coords")
        radius = Map.get(query_params, "radius", 0.0) |> String.to_float()

        # Diviser la chaîne de coordonnées en plusieurs paires de longitude et latitude
        coords = String.split(coords, ";")

        # Initialisation de la variable pour le barycentre
        total_points = length(coords)

        # Etape 1: Calcul du barycentre
        {total_latitude, total_longitude} =
          Enum.reduce(coords, {0.0, 0.0}, fn coord, {acc_lat, acc_long} ->
            [longitude, latitude] = String.split(coord, ",")
            {acc_lat + String.to_float(latitude), acc_long + String.to_float(longitude)}
          end)

        # Define the size of the square in degrees (200m in degrees)
        square_size_in_degrees = 200.0 / 111_045.0

        barycentre_latitude = (total_latitude / total_points) - square_size_in_degrees / 2
        barycentre_longitude = (total_longitude / total_points) - square_size_in_degrees / 2

        # Etape 2: Calcul de la plus grande distance au barycentre
        max_distance =
          Enum.reduce(coords, 0.0, fn coord, acc_dist ->
            [longitude, latitude] = String.split(coord, ",")
            # Utilisez ici votre méthode de calcul de distance
            distance =
              calculate_distance(
                barycentre_latitude,
                barycentre_longitude,
                String.to_float(latitude),
                String.to_float(longitude)
              )

            max(acc_dist, distance)
          end)

        # Etape 3: Utilisation du nouveau rayon
        # ajoutez 300m
        new_radius = max_distance + 0.3

        # Créer un MapSet pour stocker des carreaux uniques et un map pour les totaux
        carreaux_mapset = MapSet.new()
        age_totals = %{"ind_0_17" => 0, "ind_18_24" => 0, "ind_25_64" => 0, "ind_65_80p" => 0}

        filtered_carreaux =
          Carreaux.get_filtered_carreaux(barycentre_latitude, barycentre_longitude, new_radius)

        # Appeler la fonction du contexte Carreaux pour chaque paire de coordonnées
        {carreaux_mapset, age_totals} =
          Enum.reduce(coords, {carreaux_mapset, age_totals}, fn coord, {acc_set, acc_totals} ->
            [longitude, latitude] = String.split(coord, ",")
            longitude = String.to_float(longitude)
            latitude = String.to_float(latitude)

            carreaux =
              Carreaux.get_carreaux_in_radius_5(latitude, longitude, radius, filtered_carreaux)
              |> Enum.map(&Carreaux.create_feature/1)

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
end

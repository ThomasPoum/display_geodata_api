defmodule DisplayGeodataApi.CarreauxController do
  import Plug.Conn
  alias DisplayGeodataApi.Carreaux.Carreaux
  # alias GeodataApi.Tokens.Tokens
  alias DisplayGeodataApi.Queries

  def init(opts), do: opts

  def call(conn, _opts) do
    new_new_new_search(conn)
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
    # IO.inspect("==========")
    # IO.inspect(conn)
    # IO.inspect("==========")
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
              Carreaux.get_carreaux_in_radius_2(latitude, longitude, radius)
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
        |> IO.inspect()

      {:error, error_message} ->
        conn
        |> put_resp_content_type("application/json")
        |> put_resp_header("access-control-allow-origin", "*")
        |> send_resp(400, Jason.encode!(%{error: error_message}))
        |> halt()
    end
  end
end

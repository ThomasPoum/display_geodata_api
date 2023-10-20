defmodule DisplayGeodataApi.Carreaux.Carreaux do
  @moduledoc """
  Ce module contient les fonctions de manipulation des données des carreaux.
  """

  import Ecto.Query
  alias DisplayGeodataApi.Repo
  alias DisplayGeodataApi.Schemas.Carreau
  alias DisplayGeodataApi.CarreauxController

  @doc """
  Retourne un carreau en fonction de son id.

  ## Examples

      iex> GeodataApi.Carreaux.Carreaux.get_carreau("1234")
      %Carreaux{...}

  """
  def get_carreau(id) do
    Repo.get(Carreau, id)
    |> Jason.encode!()
  end

  @doc """
  Retourne tous les carreaux.

  ## Examples

      iex> GeodataApi.Carreaux.Carreaux.get_all_carreaux()
      [%Carreaux{...}, %Carreaux{...}]

  """
  def get_all_carreaux() do
    Repo.all(Carreau)
    |> Enum.to_list()
    |> Jason.encode!()
  end

  @doc """
  Retourne tous les carreaux dont l'indicateur est supérieur ou égal à la valeur donnée.

  ## Examples

      iex> GeodataApi.Carreaux.Carreaux.get_carreaux(10.5)
      [%Carreaux{...}, %Carreaux{...}]

  """
  def get_carreaux(value) do
    q = from(c in Carreau, where: c.ind >= ^value)
    Repo.all(q)
  end

  @doc """
  Compte le nombre de carreaux dont l'indicateur est supérieur ou égal à la valeur donnée.

  ## Examples

      iex> GeodataApi.Carreaux.Carreaux.count_carreaux(%{"value" => "10.5"})
      "2"

  """
  def count_carreaux(query_params) do
    {value, _} =
      query_params
      |> Map.values()
      |> Enum.at(0)
      |> Float.parse()

    get_carreaux(value)
    |> Enum.count()
    |> Jason.encode!()
  end

  @doc """
  Obtient une liste de carreaux dont le centre se trouve dans un rayon spécifié autour d'une paire de coordonnées de latitude et de longitude.

  ## Params

  - `latitude` - La latitude du centre du cercle de recherche, en degrés.
  - `longitude` - La longitude du centre du cercle de recherche, en degrés.
  - `radius_km` - Le rayon du cercle de recherche, en kilomètres.

  ## Examples

      iex> get_carreaux_in_radius_2(48.8566, 2.3522, 5)
      [%Carreau{latitude: 48.8567, longitude: 2.3522, ...}, %Carreau{latitude: 48.8565, longitude: 2.3524, ...}]

  ## Returns

  Une liste de carreaux dont le centre se trouve dans le rayon spécifié autour de la paire de coordonnées de latitude et de longitude.

  """
  def get_carreaux_in_radius_2(latitude, longitude, radius_km) do
    # Convert the radius from kilometers to degrees
    radius_in_degrees = radius_km / 111.045

    # Define the size of the square in degrees (200m in degrees)
    square_size_in_degrees = 200.0 / 111_045.0

    # Define a query for the database
    query =
      from(c in Carreau,
        # Check if the center of the square is within the radius
        where:
          fragment(
            "? >= ? - ? and ? <= ? + ? and
                      ? >= ? - ? and ? <= ? + ?",
            c.latitude + ^square_size_in_degrees / 2.0,
            type(^latitude, :float),
            type(^radius_in_degrees, :float),
            c.latitude + ^square_size_in_degrees / 2.0,
            type(^latitude, :float),
            type(^radius_in_degrees, :float),
            c.longitude + ^square_size_in_degrees / 2.0,
            type(^longitude, :float),
            type(^radius_in_degrees, :float),
            c.longitude + ^square_size_in_degrees / 2.0,
            type(^longitude, :float),
            type(^radius_in_degrees, :float)
          )
      )

    # Execute the query
    Repo.all(query)
  end

  def get_carreaux_in_radius_3(latitude, longitude, radius_km) do
    # Define the size of the square in degrees (200m in degrees)
    square_size_in_degrees = 200.0 / 111_045.0

    point_str =
      "SRID=4326;POINT(#{longitude - square_size_in_degrees / 2} #{latitude - square_size_in_degrees / 2})"

    radius_in_meter = (radius_km * 1000) |> trunc()

    from(c in DisplayGeodataApi.Schemas.Carreau,
      where:
        fragment(
          "ST_DWithin(
            ST_GeogFromText(?),
            geography(?),
            ?
          )",
          ^point_str,
          c.coordinates,
          ^radius_in_meter
        )
    )
    |> DisplayGeodataApi.Repo.all()
  end

  def get_carreaux_in_radius_4(latitude, longitude, radius_km) do
    # Define the size of the square in degrees (200m in degrees)
    square_size_in_degrees = 200.0 / 111_045.0

    point_str =
      "SRID=4326;POINT(#{longitude - square_size_in_degrees / 2} #{latitude - square_size_in_degrees / 2})"

    radius_in_meter = (radius_km * 1000) |> trunc()
    # Implémentez cette fonction
    geohash_prefix = compute_geohash_prefix(latitude, longitude)

    from(c in DisplayGeodataApi.Schemas.Carreau,
      where: like(c.geohash, ^"#{geohash_prefix}%"),
      where:
        fragment(
          "ST_DWithin(
          ST_GeogFromText(?),
          geography(?),
          ?
        )",
          ^point_str,
          c.coordinates,
          ^radius_in_meter
        )
    )
    |> DisplayGeodataApi.Repo.all()
  end

  def get_carreaux_in_radius_5(latitude, longitude, radius_km, filtered_carreaux) do
    # Convertissez le rayon en mètres
    radius_in_meter = (radius_km * 1000) |> trunc()

    # Point central pour la recherche
    coords_point_str = [longitude, latitude]

    # Filtrez l'ensemble pré-filtré de carreaux en mémoire
    filtered_result =
      Enum.filter(filtered_carreaux, fn carreau ->
        # Utilisez une fonction qui vérifie si le carreau est dans le rayon spécifié
        # Vous pouvez utiliser une fonction de géolocalisation pour comparer les distances
        is_within_radius?(coords_point_str, carreau.coordinates, radius_in_meter)
      end)

    # Renvoyez l'ensemble filtré
    filtered_result
  end

  defp is_within_radius?(coords_point_str, carreau_coordinates, radius_in_meter) do
    # Extraire les coordonnées de point_str et carreau_coordinates
    # ["SRID=4326;POINT(", coord_str, ")", _] = String.split(point_str, ["(", ")"])
    [longitude1, latitude1] = coords_point_str
      # String.split(coord_str, " ") |> Enum.map(&String.to_float/1)

      # IO.inspect(carreau_coordinates.coordinates, label: "carreau_coordinates")

    # ["SRID=4326;POINT(", carreau_coord_str, ")"] = String.split(carreau_coordinates, ["(", ")"])
    {longitude2, latitude2} = carreau_coordinates.coordinates
      # String.split(carreau_coord_str, " ") |> Enum.map(&String.to_float/1)

    # Utilisez la fonction calculate_distance pour obtenir la distance en kilomètres
    distance_km =
      CarreauxController.calculate_distance(latitude1, longitude1, latitude2, longitude2)

    # Convertir la distance en mètres pour la comparaison
    distance_m = distance_km * 1000.0

    # Vérifier si la distance est dans le rayon spécifié
    distance_m <= radius_in_meter
  end

  @spec compute_geohash_prefix(float(), float(), integer()) :: String.t()
  def compute_geohash_prefix(latitude, longitude, precision \\ 5) do
    geohash = Geohash.encode(latitude, longitude, 6)
    String.slice(geohash, 0, precision)
  end

  @doc """
  Obtient une liste unique de carreaux qui sont dans un rayon spécifié autour de plusieurs paires de coordonnées de latitude et de longitude.

  ## Params

  - `locations` - Une liste de tuples, où chaque tuple est une paire de coordonnées de latitude et de longitude.
  - `radius_km` - Le rayon autour de chaque paire de coordonnées, en kilomètres, dans lequel chercher des carreaux.

  ## Examples

      iex> get_carreaux_for_multiple_locations([{48.8566, 2.3522}, {45.5017, -73.5673}], 5)
      [%Carreau{latitude: 48.8567, longitude: 2.3522, ...}, %Carreau{latitude: 45.5018, longitude: -73.5672, ...}]

  ## Returns

  Une liste unique de carreaux qui sont dans le rayon spécifié autour de chaque paire de coordonnées.

  """
  def get_carreaux_for_multiple_locations(locations, radius_km) do
    Enum.flat_map(locations, fn {latitude, longitude} ->
      get_carreaux_in_radius_4(latitude, longitude, radius_km)
    end)
    # |> List.flatten()
    |> Enum.uniq()
  end

  @doc """
  Creates a feature representing a 200m x 200m square from the given longitude and latitude coordinates.

  ## Examples

      iex> carreau = %{
      ...>   id: 1,
      ...>   name: "Square A",
      ...>   longitude: -0.123,
      ...>   latitude: 51.456
      ...> }
      iex> create_feature(carreau)
      %{
        "type" => "Feature",
        "geometry" => %{
          "type" => "Polygon",
          "coordinates" => [[[-0.123, 51.456], [-0.123, 51.4562], [-0.1228, 51.4562], [-0.1228, 51.456], [-0.123, 51.456]]]
        },
        "properties" => %{
          "id" => 1,
          "name" => "Square A"
        }
      }

      iex> carreau = %{
      ...>   id: 2,
      ...>   name: "Square B",
      ...>   longitude: 2.345,
      ...>   latitude: 48.789
      ...> }
      iex> create_feature(carreau)
      %{
        "type" => "Feature",
        "geometry" => %{
          "type" => "Polygon",
          "coordinates" => [[[2.345, 48.789], [2.345, 48.7892], [2.3452, 48.7892], [2.3452, 48.789], [2.345, 48.789]]]
        },
        "properties" => %{
          "id" => 2,
          "name" => "Square B"
        }
      }
  """
  def create_feature(carreau) do
    # Extract longitude and latitude from carreau
    longitude = carreau.longitude
    latitude = carreau.latitude

    # Calculate the coordinates for the square
    bottom_left = {longitude, latitude}
    bottom_right = {longitude + 0.00254, latitude + 0.000265}
    top_right = {longitude + 0.00256 - 0.00038, latitude + 0.001815 + 0.000265 - 0.00004}
    top_left = {longitude - 0.00036, latitude + 0.001815 - 0.00004}

    ind_0_17 = carreau.ind_0_3 + carreau.ind_4_5 + carreau.ind_6_10 + carreau.ind_11_17
    ind_18_24 = carreau.ind_18_24
    ind_25_64 = carreau.ind_25_39 + carreau.ind_40_54 + carreau.ind_55_64
    ind_65_80p = carreau.ind_65_79 + carreau.ind_80p

    # Create the feature
    feature = %{
      "type" => "Feature",
      "geometry" => %{
        "type" => "Polygon",
        "coordinates" => [
          [
            Tuple.to_list(bottom_left),
            Tuple.to_list(bottom_right),
            Tuple.to_list(top_right),
            Tuple.to_list(top_left),
            Tuple.to_list(bottom_left)
          ]
        ]
      },
      "properties" => %{
        "id" => carreau.id,
        "name" => carreau.idINSPIRE,
        "ind_0_17" => ind_0_17,
        "ind_18_24" => ind_18_24,
        "ind_25_64" => ind_25_64,
        "ind_65_80p" => ind_65_80p
      }
    }

    feature
  end

  def get_filtered_carreaux(barycentre_latitude, barycentre_longitude, new_radius_km) do
    new_radius_in_meter = (new_radius_km * 1000) |> trunc()
    barycentre_point_str = "SRID=4326;POINT(#{barycentre_longitude} #{barycentre_latitude})"

    from(c in DisplayGeodataApi.Schemas.Carreau,
      where:
        fragment(
          "ST_DWithin(
          ST_GeogFromText(?),
          geography(?),
          ?
        )",
          ^barycentre_point_str,
          c.coordinates,
          ^new_radius_in_meter
        )
    )
    |> DisplayGeodataApi.Repo.all()
  end
end

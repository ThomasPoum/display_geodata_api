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
    # Define the size of the square in degrees (200m in degrees)
    square_size_in_degrees = 200.0 / 111_045.0

    # Conversion du rayon en mètres
    radius_in_meter = (radius_km * 1000) |> trunc()

    # Point central pour la recherche
    coords_point_str = [
      longitude - square_size_in_degrees / 2,
      latitude - square_size_in_degrees / 2
    ]

    # Filtre de l'ensemble pré-filtré de carreaux en mémoire
    filtered_result =
      Enum.filter(filtered_carreaux, fn carreau ->
        # Utilisation d'une fonction qui vérifie si le carreau est dans le rayon spécifié
        is_within_radius?(coords_point_str, carreau.coordinates, radius_in_meter)
      end)

    # Renvoyez l'ensemble filtré
    filtered_result
  end

  defp is_within_radius?(coords_point_str, carreau_coordinates, radius_in_meter) do
    # Extraction les coordonnées de point_str et carreau_coordinates
    [longitude1, latitude1] = coords_point_str

    {longitude2, latitude2} = carreau_coordinates.coordinates

    # Utilisation la fonction calculate_distance pour obtenir la distance en kilomètres
    distance_km =
      CarreauxController.calculate_distance(latitude1, longitude1, latitude2, longitude2)

    # Conversion la distance en mètres pour la comparaison
    distance_m = distance_km * 1000.0

    # Vérification si la distance est dans le rayon spécifié
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

  def create_feature_2(carreau) do
    [y, x] = extract_coordinates(carreau.idINSPIRE)
    {bottom_left, bottom_right, top_left, top_right} = calculate_epsg3035_sommets(x, y)

    gps_bottom_left = convert_to_gps(bottom_left)
    gps_bottom_right = convert_to_gps(bottom_right)
    gps_top_left = convert_to_gps(top_left)
    gps_top_right = convert_to_gps(top_right)

    offset = calculate_offset(gps_bottom_left, {carreau.longitude, carreau.latitude})

    new_gps_bottom_left = apply_offset(gps_bottom_left, offset)
    new_gps_bottom_right = apply_offset(gps_bottom_right, offset)
    new_gps_top_left = apply_offset(gps_top_left, offset)
    new_gps_top_right = apply_offset(gps_top_right, offset)

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
            Tuple.to_list(new_gps_bottom_left),
            Tuple.to_list(new_gps_bottom_right),
            Tuple.to_list(new_gps_top_right),
            Tuple.to_list(new_gps_top_left),
            Tuple.to_list(new_gps_bottom_left)
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

  @doc """
    Extracts the X and Y coordinates in EPSG3035 format from an INSPIRE grid name.

    This function uses a regular expression to find the numerical values corresponding to
    latitude (N) and longitude (E) in an INSPIRE grid name. It returns a list containing
    these two numerical values.

    ## Parameters

      - `name`: A string representing the INSPIRE name of the grid.
        The expected format is something like "CRS3035RES200mN2893400E3763200".

    ## Examples

        iex> extract_coordinates("CRS3035RES200mN2893400E3763200")
        [2893400, 3763200]

        iex> extract_coordinates("N123E456")
        [123, 456]

    ## Returns

    Returns a list of two integers: `[x, y]`.

  """
  def extract_coordinates(name) do
    Regex.scan(~r/N(\d+)E(\d+)/, name)
    |> List.flatten()
    |> Enum.drop(1)
    |> Enum.map(&String.to_integer/1)
  end

  def calculate_epsg3035_sommets(x, y) do
    bottom_left = {x, y}
    bottom_right = {x + 200, y}
    top_left = {x, y + 200}
    top_right = {x + 200, y + 200}
    {bottom_left, bottom_right, top_left, top_right}
  end

  @doc """
  Converts a coordinate pair from the Lambert Azimuthal Equal Area projection (EPSG 3035)
  to the WGS 84 coordinate system.

  This function takes a tuple of x and y coordinates in the EPSG 3035 coordinate system,
  and returns a tuple of longitude and latitude in the WGS 84 system.

  ## Parameters

  - `{x, y}`: A tuple containing the x and y coordinates in the EPSG 3035 coordinate system.

  ## Returns

  - `{lon_deg, lat_deg}`: A tuple containing the longitude and latitude in degrees in the WGS 84 system.

  ## Examples

      iex> CoordinateConverter.convert_to_gps({4321000, 3210000})
      {10.0, 52.0}

      iex> CoordinateConverter.convert_to_gps({4421000, 3310000})
      {10.8, 53.2}

  Note: The function assumes that the input coordinates are valid coordinates in the EPSG 3035 system.
  """
  def convert_to_gps({x, y}) do
    # Parameters for EPSG 3035
    # latitude of natural origin in degrees
    lat_0 = 52.0
    # longitude of natural origin in degrees
    lon_0 = 10.0
    # in meters
    false_easting = 4_321_000.0
    # in meters
    false_northing = 3_210_000.0
    # Earth's radius in meters
    r = 6_371_000.0

    # Convert the origin latitude and longitude to radians
    lat_0_rad = degrees_to_radians(lat_0)
    lon_0_rad = degrees_to_radians(lon_0)

    # Adjust for the false easting and northing
    x = x - false_easting
    y = y - false_northing

    # Inverse equations for Lambert Azimuthal Equal Area projection
    rho = :math.sqrt(x * x + y * y)
    c = 2 * :math.asin(rho / (2 * r))

    lat =
      :math.asin(
        :math.cos(c) * :math.sin(lat_0_rad) +
          y * :math.sin(c) * :math.cos(lat_0_rad) / rho
      )

    lon =
      lon_0_rad +
        :math.atan2(
          x * :math.sin(c),
          rho * :math.cos(lat_0_rad) * :math.cos(c) -
            y * :math.sin(lat_0_rad) * :math.sin(c)
        )

    # Convert the latitude and longitude to degrees
    lat_deg = radians_to_degrees(lat)
    lon_deg = radians_to_degrees(lon)

    {lon_deg, lat_deg}
  end

  def degrees_to_radians(deg) do
    deg * :math.pi() / 180
  end

  def radians_to_degrees(rad) do
    rad * 180 / :math.pi()
  end

  def calculate_offset({lon1, lat1}, {lon2, lat2}) do
    lat_offset = lat2 - lat1
    lon_offset = lon2 - lon1
    {lon_offset, lat_offset}
  end

  def apply_offset({lon, lat}, {lon_offset, lat_offset}) do
    new_lat = lat + lat_offset
    new_lon = lon + lon_offset
    {new_lon, new_lat}
  end

  @doc """
  Returns the maximum distance (in km) between coordinates.
  coords must be a list of strings in the format "longitude,latitude"
  iex> CarreauxController.max_distance_between_coords(["1,2","3,4"])
  iex> 1.4142135623730951
  """
  def max_distance_between_coords(coords) do
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

    barycentre_latitude = total_latitude / total_points - square_size_in_degrees / 2
    barycentre_longitude = total_longitude / total_points - square_size_in_degrees / 2

    # Etape 2: Calcul de la plus grande distance au barycentre
    max_distance =
      Enum.reduce(coords, 0.0, fn coord, acc_dist ->
        [longitude, latitude] = String.split(coord, ",")
        # Utilisez ici votre méthode de calcul de distance
        distance =
          CarreauxController.calculate_distance(
            barycentre_latitude,
            barycentre_longitude,
            String.to_float(latitude),
            String.to_float(longitude)
          )

        max(acc_dist, distance)
      end)

      {max_distance, barycentre_latitude, barycentre_longitude}
  end
end

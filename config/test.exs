import Config

# Configure your database
#
# The MIX_TEST_PARTITION environment variable can be used
# to provide built-in test partitioning in CI environment.
# Run `mix help test` for more information.
config :display_geodata_api, DisplayGeodataApi.Repo,
  username: "postgres",
  password: "postgres",
  hostname: "localhost",
  database: "display_geodata_api_test#{System.get_env("MIX_TEST_PARTITION")}",
  pool: Ecto.Adapters.SQL.Sandbox,
  pool_size: 10

# We don't run a server during test. If one is required,
# you can enable the server option below.
config :display_geodata_api, DisplayGeodataApiWeb.Endpoint,
  http: [ip: {127, 0, 0, 1}, port: 4002],
  secret_key_base: "I8TgvGsL2++G31/rZT1J+lzfypKpoozOCR6XXTG7R9zLk9BYno0JOFkHWwOcmBgP",
  server: false

# In test we don't send emails.
config :display_geodata_api, DisplayGeodataApi.Mailer, adapter: Swoosh.Adapters.Test

# Disable swoosh api client as it is only required for production adapters.
config :swoosh, :api_client, false

# Print only warnings and errors during test
config :logger, level: :warning

# Initialize plugs at runtime for faster test compilation
config :phoenix, :plug_init_mode, :runtime

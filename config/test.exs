import Config
config :starter_kit, token_signing_secret: "jOlKVjSgGbRsy14P7MRyb1zMhioN9FgM"
config :bcrypt_elixir, log_rounds: 1
config :ash, disable_async?: true

# Oban jobs don't execute automatically in tests — enqueue them and assert with
# `Oban.Testing`, or drain them explicitly with `Oban.drain_queue/2`.
config :starter_kit, Oban, testing: :manual

# Configure your database
#
# The MIX_TEST_PARTITION environment variable can be used
# to provide built-in test partitioning in CI environment.
# Run `mix help test` for more information.
config :starter_kit, StarterKit.Repo,
  username: "postgres",
  password: "postgres",
  hostname: "localhost",
  database: "starter_kit_test#{System.get_env("MIX_TEST_PARTITION")}",
  pool: Ecto.Adapters.SQL.Sandbox,
  pool_size: System.schedulers_online() * 2

# We don't run a server during test. If one is required,
# you can enable the server option below.
config :starter_kit, StarterKitWeb.Endpoint,
  http: [ip: {127, 0, 0, 1}, port: 4002],
  secret_key_base: "NJ3b5K6UmADXP7aaHyqI1s87V7y2H3DneUfRhValRzy8XGF4K+QOmYbC+QlmdxBU",
  server: false

# In test we don't send emails
config :starter_kit, StarterKit.Mailer, adapter: Swoosh.Adapters.Test

# Disable swoosh api client as it is only required for production adapters
config :swoosh, :api_client, false

# Print only warnings and errors during test
config :logger, level: :warning

# Initialize plugs at runtime for faster test compilation
config :phoenix, :plug_init_mode, :runtime

# Sort query params output of verified routes for robust url comparisons
config :phoenix,
  sort_verified_routes_query_params: true

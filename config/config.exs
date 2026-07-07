# This file is responsible for configuring your application
# and its dependencies with the aid of the Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.

# General application configuration
import Config

config :spark,
  formatter: [
    "Ash.Resource": [
      section_order: [:admin, :authentication, :token, :oban, :user_identity, :postgres]
    ],
    "Ash.Domain": [section_order: [:admin, :resources]]
  ]

config :ash, known_types: [AshPostgres.Timestamptz, AshPostgres.TimestamptzUsec]

config :starter_kit,
  ecto_repos: [StarterKit.Repo],
  generators: [timestamp_type: :utc_datetime],
  ash_domains: [
    StarterKit.Accounts,
    # DEMO: demo Notes domain — bin/remove_demo strips this line
    StarterKit.Notes
  ],
  ash_authentication: [return_error_on_invalid_magic_link_token?: true]

# Configure the endpoint
config :starter_kit, StarterKitWeb.Endpoint,
  url: [host: "localhost"],
  adapter: Bandit.PhoenixAdapter,
  render_errors: [
    formats: [json: StarterKitWeb.ErrorJSON],
    layout: false
  ],
  pubsub_server: StarterKit.PubSub,
  live_view: [signing_salt: "R0E3ERIA"]

# Configure the mailer
#
# By default it uses the "Local" adapter which stores the emails
# locally. You can see the emails in your browser, at "/dev/mailbox".
#
# For production it's recommended to configure a different adapter
# at the `config/runtime.exs`.
config :starter_kit, StarterKit.Mailer, adapter: Swoosh.Adapters.Local

# The From identity for all outgoing mail (the auth senders read this). Change it
# to your verified sending domain before going to production.
config :starter_kit, :email_from, {"StarterKit", "noreply@example.com"}

# Configure Elixir's Logger
config :logger, :default_formatter,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

# Use Jason for JSON parsing in Phoenix
config :phoenix, :json_library, Jason

# Register the JSON:API media type (R13) so Phoenix parses/serves it. If a stale
# compile of :mime complains, run `mix deps.compile mime --force`.
config :mime,
  extensions: %{"json" => "application/vnd.api+json"},
  types: %{"application/vnd.api+json" => ["json"]}

# PRUNE:WEB
# Inertia.js server adapter (web flavor; pruned for --api).
config :inertia, endpoint: StarterKitWeb.Endpoint

# phoenix_vite: how to invoke the local npm/vite toolchain for asset install/dev/build.
config :phoenix_vite, PhoenixVite.Npm,
  assets: [args: [], cd: Path.expand("../assets", __DIR__)],
  vite: [
    args: ~w(exec -- vite),
    cd: Path.expand("../assets", __DIR__),
    env: %{"MIX_BUILD_PATH" => Mix.Project.build_path()}
  ]

# PRUNE:END

# PRUNE:WEB
# Content-Security-Policy applied by the browser pipeline. This baseline fits the
# Inertia + Vite production build, where every asset is served same-origin. dev.exs
# relaxes it for the Vite dev server + HMR. Extend it for any CDN, analytics, or font
# host your app talks to.
config :starter_kit,
       :content_security_policy,
       "default-src 'self'; connect-src 'self'; img-src 'self' data:; " <>
         "style-src 'self' 'unsafe-inline'; script-src 'self'; " <>
         "base-uri 'self'; frame-ancestors 'self'; object-src 'none'"

# PRUNE:END

# The LiveView admin surfaces (AshAdmin, LiveDashboard) need a looser CSP than a
# plain page: LiveView injects inline bootstrap and connects over a websocket.
config :starter_kit,
       :admin_content_security_policy,
       "default-src 'self'; connect-src 'self' ws: wss:; img-src 'self' data:; " <>
         "style-src 'self' 'unsafe-inline'; script-src 'self' 'unsafe-inline' 'unsafe-eval'; " <>
         "base-uri 'self'; frame-ancestors 'self'; object-src 'none'"

# Background jobs (R4). Oban runs on Postgres with a Postgres-based notifier (no
# extra pub/sub infra). ash_oban merges each resource's triggers and scheduled
# actions into this config at boot (see StarterKit.Application). The Cron plugin
# drives them; the Pruner discards finished jobs after a week.
config :starter_kit, Oban,
  repo: StarterKit.Repo,
  notifier: Oban.Notifiers.Postgres,
  queues: [default: 10, mailers: 20],
  plugins: [
    Oban.Plugins.Cron,
    {Oban.Plugins.Pruner, max_age: 60 * 60 * 24 * 7}
  ]

# ash_oban jobs are system operations, so they run unauthorized — user-facing access
# is still guarded by resource policies. `pro?: false` selects the OSS cron plugin.
config :ash_oban, pro?: false, authorize?: false

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{config_env()}.exs"

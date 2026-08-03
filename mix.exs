defmodule StarterKit.MixProject do
  use Mix.Project

  def project do
    [
      app: :starter_kit,
      version: "0.1.0",
      elixir: "~> 1.18",
      elixirc_paths: elixirc_paths(Mix.env()),
      start_permanent: Mix.env() == :prod,
      aliases: aliases(),
      deps: deps(),
      listeners: [Phoenix.CodeReloader],
      usage_rules: usage_rules(),
      dialyzer: [
        plt_local_path: "priv/plts",
        plt_core_path: "priv/plts",
        plt_add_apps: [:mix, :ex_unit],
        ignore_warnings: ".dialyzer_ignore.exs"
      ]
    ]
  end

  # Configuration for the OTP application.
  #
  # Type `mix help compile.app` for more information.
  def application do
    [
      mod: {StarterKit.Application, []},
      extra_applications: [:logger, :runtime_tools]
    ]
  end

  def cli do
    [
      preferred_envs: [precommit: :test]
    ]
  end

  # R19: sync package usage-rules into AGENTS.md's managed section so agents get
  # Ash-ecosystem + Phoenix guidance in context. Re-run with `mix usage_rules.sync`
  # after adding deps; the regexes pick up new ash_*/phoenix_* packages automatically
  # (and the birth-script prune re-syncs so a pruned flavor never references removed deps).
  defp usage_rules do
    [
      file: "AGENTS.md",
      usage_rules: [:usage_rules, :ash, ~r/^ash_/, :phoenix, ~r/^phoenix_/]
    ]
  end

  # Specifies which paths to compile per environment.
  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  # Specifies your project dependencies.
  #
  # Type `mix help deps` for examples and options.
  defp deps do
    [
      {:bcrypt_elixir, "~> 3.0"},
      {:picosat_elixir, "~> 0.2"},
      {:ash_authentication, "~> 4.0"},
      # Ash domain layer (R2). `:ash` is listed directly so its usage-rules sync
      # into AGENTS.md (R19); ash_postgres/ash_phoenix bring the data layer + web glue.
      {:ash, "~> 3.0"},
      {:ash_phoenix, "~> 2.0"},
      {:ash_postgres, "~> 2.0"},
      {:tidewave, "~> 0.8", only: [:dev]},
      {:usage_rules, "~> 1.0", only: [:dev]},
      {:phoenix, "~> 1.8.8"},
      {:phoenix_ecto, "~> 4.5"},
      {:ecto_sql, "~> 3.13"},
      {:postgrex, ">= 0.0.0"},
      {:phoenix_live_dashboard, "~> 0.8.3"},
      {:swoosh, "~> 1.16"},
      {:req, "~> 0.5"},
      {:telemetry_metrics, "~> 1.0"},
      {:telemetry_poller, "~> 1.0"},
      {:jason, "~> 1.2"},
      {:dns_cluster, "~> 0.2.0"},
      {:bandit, "~> 1.5"},

      # Jobs, admin, observability (R4, R5, R6). Oban runs background jobs; ash_oban
      # integrates them with Ash actions (triggers + scheduled actions). AshAdmin is a
      # LiveView admin UI, prod-gated in the router. ecto_psql_extras powers
      # LiveDashboard's Ecto stats page. All three surfaces stay in both flavors (KTD7).
      {:oban, "~> 2.23"},
      {:ash_oban, "~> 0.8"},
      {:ash_admin, "~> 1.1"},
      {:ecto_psql_extras, "~> 0.8"},

      # JSON:API layer (R13, R14). ash_json_api exposes resources as JSON:API with an
      # auto-generated OpenAPI spec; open_api_spex serves the Swagger UI docs page.
      {:ash_json_api, "~> 1.7"},
      {:open_api_spex, "~> 3.22"},

      # PRUNE:WEB
      # Web flavor (R9): Inertia.js server adapter (pinned to the stable 2.x line,
      # KTD1) + phoenix_vite, which feeds Vite's manifest into Phoenix's static
      # digesting so no phx.digest hacks are needed (KTD2). Both pruned for --api.
      {:inertia, "~> 2.6"},
      {:phoenix_vite, "~> 0.4"},
      # PRUNE:END

      # Quality gate (KTD10: Styler deliberately omitted — credo --strict covers style,
      # and Spark.Formatter is the only formatter plugin).
      {:credo, "~> 1.7", only: [:dev, :test], runtime: false},
      {:dialyxir, "~> 1.4", only: [:dev, :test], runtime: false},
      {:sobelow, "~> 0.14", only: [:dev, :test], runtime: false},
      {:mix_audit, "~> 2.1", only: [:dev, :test], runtime: false},

      # Code-generation / installer tooling for the Ash ecosystem (dev-only).
      {:igniter, "~> 0.8", only: [:dev]},
      # Spark.Formatter needs sourceror at format time. igniter pulls it in :dev, but
      # the gate runs `mix format` in :test — list it explicitly for both envs.
      {:sourceror, "~> 1.0", only: [:dev, :test]},

      # Testing harness (R17): Mimic for mocks, stream_data for property tests.
      # Ash.Generator (in :ash) supplies fixtures — no separate factory library.
      {:mimic, "~> 2.3", only: :test},
      # PRUNE:WEB
      # Browser E2E (R17, KTD8): drives the Inertia UI in a real browser. Tagged
      # `:playwright` and excluded from the fast gate; CI's birth-matrix web leg
      # runs it via `mix test --only playwright`.
      {:phoenix_test_playwright, "~> 0.15", only: :test, runtime: false},
      # PRUNE:END
      # No :only restriction — :ash depends on stream_data in all envs, so scoping
      # it here would diverge from ash/mix.exs.
      {:stream_data, "~> 1.0"}
    ]
  end

  # Aliases are shortcuts or tasks specific to the current project.
  # For example, to install project dependencies and perform other setup tasks, run:
  #
  #     $ mix setup
  #
  # See the documentation for `Mix` for more info on aliases.
  defp aliases do
    [
      setup: [
        "deps.get",
        # PRUNE:WEB
        "assets.setup",
        # PRUNE:END
        "ash.setup",
        "run priv/repo/seeds.exs"
      ],
      "ecto.setup": ["ecto.create", "ecto.migrate", "run priv/repo/seeds.exs"],
      "ecto.reset": ["ecto.drop", "ecto.setup"],
      test: [
        "ash.setup --quiet",
        # PRUNE:WEB
        # Build the Vite manifest into priv/static before the endpoint boots. Inertia
        # renders read priv/static/.vite/manifest.json at request time and phoenix_vite
        # raises File.Error if it is absent (F13). precommit runs THIS alias (not
        # `mix setup`), so the build lives here to cover a fresh --web newborn and a
        # cold checkout alike; --api prunes the whole block (no assets).
        "assets.build",
        # PRUNE:END
        "test"
      ],
      # PRUNE:WEB
      # Vite asset pipeline via phoenix_vite (web flavor). `assets.deploy` is what
      # the birth-generated Dockerfile calls (KTD6); it produces the manifest that
      # Phoenix's cache_static_manifest_latest consumes — no phx.digest.
      "assets.setup": ["phoenix_vite.npm assets install"],
      "assets.build": ["phoenix_vite.npm vite build"],
      "assets.deploy": ["assets.build"],
      # PRUNE:END
      # Single source of truth for the quality gate (KTD12). CI and docs reference
      # this alias by name; dialyzer is kept last because it is the slowest step.
      precommit: [
        "format --check-formatted",
        "compile --warnings-as-errors --force",
        # Fail fast on resource/migration/snapshot drift before the slow steps run.
        "ash_postgres.generate_migrations --check",
        "credo --strict",
        "sobelow --config",
        "deps.audit",
        "test",
        "dialyzer"
      ]
    ]
  end
end

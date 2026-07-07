# Phoenix Starter Kit

A pinned, always-green **Phoenix 1.8 / Ash 3** template. One superset repo births
<!-- PRUNE:WEB -->
an **Inertia + React + TypeScript** web project, or
<!-- PRUNE:END -->
a **JSON:API** project via a single command — optimized so AI agents can start
shipping features immediately from working, conventional code.

> **This repository is the template itself — not an application.** Don't build
> features here. Birth a project with `bin/new_project`, then build there. The
> names `starter_kit` / `StarterKit` / `starter-kit` are placeholders the birth
> script renames.

## Quickstart

```bash
# From a clean clone of this template:
bin/new_project my_app --web     # full-stack web project
#   ...or...
bin/new_project my_app --api     # JSON:API-only project (frontend pruned)

cd ../my_app
mix phx.server
```

`bin/new_project` copies the template, renames the app, prunes to the flavor,
installs dependencies, creates the database, and runs the full quality gate — the
newborn is proven green before it hands back to you. No manual setup steps.

Options: `--dir PATH` (target directory, default `../NAME`), `--skip-gate` (skip
the final gate for a faster look). The flavor flag is required — there is no
default, so the choice is always explicit.

<!-- PRUNE:WEB -->
## The two flavors

| | `--web` | `--api` |
|---|---|---|
| Rendering | Inertia.js + React 19 + TypeScript (Vite) | none — JSON:API only |
| Auth surface | session pages (sign-in, register, magic link, settings) | API keys + JWT bearer tokens |
| Frontend | `assets/` with shadcn/ui | pruned entirely |
| Shared | Ash domains, AshAdmin, LiveDashboard, Oban, the demo slice, the quality gate |

Both flavors keep the LiveView admin surfaces (AshAdmin, LiveDashboard) and the
dev mailbox — those are self-contained islands independent of the rendering choice.
<!-- PRUNE:END -->

## What's inside

- **Domain layer:** Ash 3 (resources, actions, policies) — not raw Ecto.
- **Auth:** AshAuthentication — password (bcrypt) + magic link + email
  confirmation + password reset + remember-me; hashed API keys + JWT for the API.
- **Jobs:** Oban on Postgres, integrated with Ash via AshOban (a worked trigger
  ships in the box).
- **Admin & observability:** AshAdmin at `/admin`, LiveDashboard at `/dashboard`,
  both gated to admins in production.
- **API:** AshJsonApi with an auto-generated OpenAPI spec (`/api/v1/open_api`) and
  Swagger UI (`/api/v1/docs`).
- **Quality gate:** one `mix precommit` alias — format, compile (warnings as
  errors), Credo, Sobelow, deps.audit, tests, Dialyzer. CI runs it by name.
- **Agent guidance:** `AGENTS.md`, kept in sync with package usage-rules.

## The demo slice

Every newborn ships a small end-to-end **Notes** feature (resource, owner
policies, migration, tests, plus a web page or a JSON:API endpoint) so an agent
learns the conventions from working code. When you have real features, remove it:

```bash
bin/remove_demo        # deletes the slice and re-runs the gate
```

## Deploy

`Dockerfile` and `fly.toml` are generated at deploy time, not committed (stale
committed platform config is a known footgun). When you're ready:

```bash
mix phx.gen.release --docker   # generate the release Dockerfile
fly launch --no-deploy         # Fly owns the globally-unique app name
```

On Fly Managed Postgres, run migrations against the direct (non-pooled) URL — set
`DIRECT_DATABASE_URL` and point the release migration command at it.

## Stack

| Layer | Package | Version |
|---|---|---|
| Runtime | Elixir / OTP | 1.20.1 / 29.0.2 (`.tool-versions`) |
| Framework | phoenix (Bandit) | 1.8.8 (bandit 1.12.0) |
| Domain | ash / ash_postgres / ash_phoenix | 3.29.3 / 2.x / 2.x |
| Auth | ash_authentication | 4.14.1 |
| API | ash_json_api / open_api_spex | 1.7.0 / 3.22.3 |
| Jobs | oban / ash_oban | 2.23.0 / 0.8.10 |
| Admin | ash_admin / phoenix_live_dashboard | 1.1.0 / 0.8.7 |
| Quality | credo / dialyxir / sobelow / mix_audit | 1.7.19 / 1.4.7 / 0.14.1 / 2.1.5 |
| Testing | mimic / stream_data / phoenix_test_playwright | 2.3.0 / 1.3.0 / 0.15.0 |

<!-- PRUNE:WEB -->
### Frontend stack

| Layer | Package | Version |
|---|---|---|
| Web | inertia / phoenix_vite / @inertiajs/react | 2.6.2 / 0.4.3 / 2.3.27 |
| Frontend | React / Vite / Tailwind | 19.2.7 / 8.x / 4.x |
<!-- PRUNE:END -->

Versions are pinned (lockfiles are committed) and proven green together. Freshness
is a deliberate refresh, not pull-latest — see [`docs/refresh.md`](docs/refresh.md).

## Contributions

This is a read-only reference template — see [`CONTRIBUTING.md`](CONTRIBUTING.md).
Fork it and make it yours.

## License

MIT — see [`LICENSE`](LICENSE).

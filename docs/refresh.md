# Refresh workflow

This template is a **pinned known-good snapshot**, not a pull-latest scaffold. It
stays fresh through a deliberate, agent-runnable refresh session that bumps the
pins, re-proves everything green, and cuts a new snapshot — or reverts (R26).

## When to refresh

- A grouped Dependabot PR lands (mix, npm, or GitHub Actions — see
  `.github/dependabot.yml`).
- A security advisory hits a dependency (`mix deps.audit` / `npm audit`).
- A framework minor/major you want to adopt is released (Phoenix, Ash and the
  `ash_*` ecosystem, Inertia, Oban).
- Periodically, on the weekly-cron signal from CI if it has started failing.

## Procedure

An agent (or a human) runs this end to end. Nothing merges red.

1. **Bump the pins.**
   - Elixir/OTP: edit `.tool-versions` (drives local, CI, and the generated
     Dockerfile ARGs).
   - Elixir deps: `mix deps.update <pkg>` (or `--all` for a full bump), then
     review the `mix.lock` diff.
   - Frontend: `npm --prefix assets update` (or bump specific versions in
     `assets/package.json`), then review `assets/package-lock.json`.

2. **Prove the template green.**
   ```bash
   mix precommit
   ```

3. **Prove both flavors green (the real check).** Locally mirror the birth matrix:
   ```bash
   bin/new_project refresh_web --web --dir /tmp/refresh_web
   bin/new_project refresh_api --api --dir /tmp/refresh_api
   ```
   Each births, installs, and runs its own full gate. For the web flavor also run
   the browser E2E (needs the Playwright browser installed):
   ```bash
   cd /tmp/refresh_web && mix test --only playwright
   ```
   CI runs the same matrix on push (`.github/workflows/birth-matrix.yml`).

4. **Re-sync agent docs.** If any `ash_*` / `phoenix_*` dep changed:
   ```bash
   mix usage_rules.sync
   ```

5. **Commit or revert.**
   - All green → commit the bumped `mix.lock` / `package-lock.json` / `.tool-versions`
     as the new known-good snapshot.
   - Anything red that can't be fixed quickly → revert the bump. A pinned-green
     template beats a broken bleeding-edge one.

## Scope note

The refresh handles version freshness only. Larger changes (new auth strategies,
an OAuth provider, SSR, swapping the job backend) are per-project decisions made
in a newborn, not baked into the template.

# Phoenix Starter Kit

A pinned, always-green Phoenix 1.8 / Ash 3 template. One superset repo births
either an **Inertia + React + TypeScript** web project or a **JSON:API** project
via a single command, optimized so AI agents can start shipping features
immediately.

> **This is the template itself — not an application.** Do not build features
> here. Birth a project with `bin/new_project` (added in a later unit), then
> build there. The app name `starter_kit` / `StarterKit` is a placeholder the
> birth script renames.

## Status

Under construction — see `docs/plans/` for the implementation plan. The full
quickstart, flavor guide, and deploy notes land in the final documentation unit.

## Quality gate

The definition of done is a single command:

```bash
mix precommit
```

It runs: format check, compile (warnings as errors), `credo --strict`, `sobelow`,
`deps.audit`, the test suite, and `dialyzer`. CI runs the same alias by name.

## License

MIT — see [LICENSE](LICENSE). This is a personal, read-only open-source template:
no pull requests, no support, no community governance.

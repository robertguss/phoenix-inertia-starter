# Birth And Prune Scripts Guide

## Overview

`bin/new_project` and `bin/remove_demo` are Elixir scripts, not shell scripts.
They define the template contract: birth a renamed/pruned newborn, and later
remove only the demo Notes slice.

## Where To Look

| Task | Location | Notes |
| --- | --- | --- |
| Birth flow | `bin/new_project` | Copy, validate name, rename, prune, deps/setup, Dockerfile patch, gate. |
| Web/API prune | `bin/new_project` | `PRUNE:WEB` markers and explicit deletion lists must agree. |
| Demo removal | `bin/remove_demo` | Removes Notes code/routes/migrations/tests and re-runs the gate unless skipped. |
| Refresh proof | `docs/refresh.md` | Birth both flavors during dependency refresh. |

## Conventions

- Keep scripts executable and runnable with the system Elixir available in a
  fresh template clone.
- Prefer small named steps over broad regex rewriting. Name-casing replacements
  must cover module (`StarterKit`), OTP/db/npm (`starter_kit`), and slug
  (`starter-kit`) forms.
- The flavor flag is required. There is no default flavor.
- `--skip-gate` is only a speed escape hatch; normal birth/removal proves green.
- When adding web-only files, update both prune behavior and residue checks.

## Anti-Patterns

- Do not convert these scripts to bash; cross-platform text mutation is the
  reason they are Elixir.
- Do not make `bin/remove_demo` delete non-demo feature code.
- Do not trust rename/prune without the newborn gate.
- Do not hard-code generated app names beyond placeholder replacement rules.

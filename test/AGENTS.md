# Test Guide

## Overview

Tests mirror the plural surfaces in this template: Ash resources/actions, Inertia
controllers, JSON:API, admin access, runtime config, Oban/AshOban, and optional
Playwright browser flows.

## Structure

```text
test/
|-- starter_kit/                 # Ash/domain/runtime/worker tests
|-- starter_kit_web/controllers/ # ConnTest + Inertia.Testing controller tests
|-- starter_kit_web/api/         # JSON:API route tests
|-- starter_kit_web/admin_access_test.exs
|-- e2e/                         # Playwright tests, tagged :playwright
`-- support/                     # ConnCase, DataCase, Ash.Generator fixtures
```

## Where To Look

| Task | Location | Notes |
| --- | --- | --- |
| Fixtures | `support/generators.ex` | Ash.Generator; no factory library. |
| DB sandbox | `support/data_case.ex`, `support/conn_case.ex` | Async tests use SQL sandbox owner setup. |
| Inertia assertions | `starter_kit_web/controllers/**` | Use `Inertia.Testing` for component/props/errors. |
| JSON:API assertions | `starter_kit_web/api/**` | Plain `Phoenix.ConnTest` against `/api/v1`. |
| Browser smoke | `e2e/` | Tagged `:playwright`; excluded from fast gate. |
| API policy invariant | `starter_kit/api_authorizer_invariant_test.exs` | Ensures JSON:API resources include Ash policies. |

## Conventions

- Run targeted tests with `mix test path/to/file.exs` or `mix test path/to/file.exs:LINE`.
- `mix precommit` is the final gate; it also builds Vite assets before tests for
  web flavor.
- Use `Phoenix.ConnTest` + `Inertia.Testing` for browser-controller behavior.
  Assert component names and props, not rendered React HTML.
- Use `Mimic` for mailer stubs and `stream_data` only where property coverage is
  actually useful.
- Browser E2E is explicit: `mix test --only playwright`.

## Anti-Patterns

- Do not bypass Ash actions in tests except deliberate seed/setup helpers.
- Do not add a second fixture/factory system.
- Do not move Playwright into the default fast gate; CI's web leg runs it
  separately.
- Do not weaken owner/policy assertions to make demo tests easier.

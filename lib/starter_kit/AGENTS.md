# StarterKit Domain Guide

## Overview

Ash domains and resources live here. Treat `StarterKit.Accounts` and
`StarterKit.Notes` as examples of the intended public interface: controllers and
tests call domain code interfaces, not hand-built changesets.

## Structure

```text
lib/starter_kit/
|-- accounts.ex              # auth/user/API-key domain and code interfaces
|-- accounts/                # User, Token, ApiKey resources and auth senders
|-- notes.ex                 # demo domain, removed by bin/remove_demo
|-- notes/note.ex            # demo owner-scoped resource
|-- workers/                 # Oban workers that are not AshOban-generated
|-- application.ex           # OTP supervision and AshOban config
|-- repo.ex                  # AshPostgres repo
`-- secrets.ex               # AshAuthentication signing secret provider
```

## Where To Look

| Task | Location | Notes |
| --- | --- | --- |
| User auth behavior | `accounts/user.ex` | Password, magic link, reset, confirmation, policies, expiry trigger. |
| API keys | `accounts/api_key.ex` | Hash-only storage; plaintext is returned only at creation. |
| Auth routes interface | `accounts.ex` | `define/2` code interfaces used by web controllers. |
| Demo CRUD pattern | `notes.ex`, `notes/note.ex` | Use this pairing for Ash resource + domain interface shape. |
| Background jobs | `application.ex`, `workers/` | AshOban-triggered jobs are configured at app boot. |

## Conventions

- Put business behavior in Ash actions, policies, changes, validations, and
  code interfaces. Web code should orchestrate these calls.
- Prefer domain interface calls (`Accounts.sign_in_with_password`, `Notes.create_note`)
  over direct `Ash.*` calls from controllers.
- Use `authorize?: false` only for deliberate setup/admin bypasses; normal app
  code should pass an `actor`.
- Keep JSON:API-exposed resources policy-gated. `test/starter_kit/api_authorizer_invariant_test.exs`
  exists to catch regressions.
- Resource migrations and snapshots must stay in sync; `mix precommit` runs
  `ash_postgres.generate_migrations --check`.

## Anti-Patterns

- No raw Ecto context layer beside the Ash resources.
- No `require_atomic? false` unless a resource action truly needs non-atomic work.
- Do not add permanent dependencies on the demo Notes domain from non-demo code.
- Do not leak token/key plaintext after the creation action boundary.

# Powerful Functionality Ideas — Opus Pass

**Date:** 2026-07-16
**Status:** Ideation; not an implementation commitment
**Model:** Opus 4.8 (1M context)
**Scope:** High-leverage capabilities the Phoenix/Ash/Inertia **template** could ship so every newborn is more useful, robust, reliable, intuitive, and compelling — for born-app end users, for developers who birth projects, and for the AI agents that ship the next feature.

This is a third, independent ideation pass alongside two siblings:

- [`2026-07-16-powerful-functionality-ideas.md`](./2026-07-16-powerful-functionality-ideas.md) — the **grok** pass (~100-candidate pool + top 10).
- [`2026-07-16-top-10-powerful-functionality-ideas.md`](./2026-07-16-top-10-powerful-functionality-ideas.md) — the **sol-max** pass (re-ranked top 10 after codebase inspection).

## Method

This pass was run **fresh and divergent**: ideas were generated from a direct, read-through map of the actual code — the domain layer, the web layer, the frontend, and the tooling/CI/test surfaces — *before* re-reading the sibling rankings. The two prior docs were then used only for the convergence/divergence comparison at the end. The goal was maximum **new coverage**: surface the high-value gaps the first two passes under-weighted, not re-rank the same ten.

Ranking weights leverage × pragmatism, with a deliberate tie-break toward **novelty** — where two ideas are genuinely close in value, the one the prior passes already documented in depth is ranked lower, because the marginal value of *this* pass is the coverage it adds, not a third opinion on ideas already specified twice.

## Grounding: what is actually in the box

The template is deliberately thin. Four Ash resources across two domains (`Accounts`: `User`, `Token`, `ApiKey`; `Notes`: `Note`, the removable demo), one plain Oban worker, two cron-sweep AshOban triggers. The auth machinery underneath is genuinely strong (password + magic link + confirmation + API key + JWT; `store_all_tokens? true` with real server-side revocation). The web layer is Inertia + React 19 + TS with a JSON:API sibling and an OpenAPI/Swagger surface. The quality gate (`mix precommit`) and the birth pipeline (`bin/new_project`) are the template's actual product.

What drives this pass is the set of **conspicuous absences** the code map surfaced — the seams where a real app, or an agent, hits a wall immediately:

- **No admin bootstrap.** `priv/repo/seeds.exs` is empty; an `admin?` flag and an `add_admin_flag` migration exist, but nothing seeds or promotes an admin. An agent that ships an admin-gated feature has no way to log in and see it without hand-editing the database.
- **No auth test helper.** `test/support/conn_case.ex` has no `register_and_sign_in`/`log_in_user`; every authenticated controller and Playwright test wires sign-in by hand — exactly where agents write the most code.
- **Handwritten, drift-prone types.** `assets/js/types/notes.ts` and `types/auth.ts` are hand-mirrored to the server's serialized shape by discipline alone. No Ash→TS codegen, no shared error codec.
- **No app shell.** Every page rolls its own `<nav>`, `<main>`, and `<Flash>`. There is no persistent Inertia layout, no shared navigation, no theme/toast/error-boundary provider.
- **Dark mode is built but unreachable.** A full `.dark` token palette and `dark:` variants exist across the primitives, but nothing ever applies the `.dark` class — no toggle, no provider, no persistence.
- **The template's core promise is under-guarded.** The birth-matrix `--api` residue grep skips `test/` and most of `assets/`; PRUNE-marker matching is line-based `String.contains?` (an unbalanced block silently skips to EOF); the release Docker image is `docker build`-ed in CI but never booted; there is no OpenAPI response-shape snapshot.
- **The auth surface is invisible and slightly broken at the edges.** `ApiKey` is registered but exposes **zero code interfaces** (a user cannot list/create/revoke their own keys through the domain); `Token` has no `belongs_to :user`, so per-user session queries aren't expressible; `monitor_fields [:email]` implies reconfirm-on-email-change, but `confirm_on_update? false` and no action accepts `:email`, so there is no email-change or resend-confirmation path.
- **Stack affordances installed but idle:** Ash aggregates (zero), `Ash.Notifier.PubSub` (zero, despite a supervised `Phoenix.PubSub` and an Inertia frontend), pagination on any read action (zero, including the demo the newborn copies), soft-delete/archival (hard deletes only), optimistic locking (none).

---

## Top 5 (best to worst)

### 1. `mix starter.gen.slice` — the vertical-slice compiler

**What:** One command turns a resource name + fields + ownership + target surfaces into a complete, conventional feature slice in the exact shape of Notes: Ash resource + actions + policies + code interfaces, migration + snapshot, Inertia controller/pages/form/list *and/or* AshJsonApi routes + OpenAPI, generated TS types, and the full test set (action, policy, controller, JSON:API, Playwright). `--dry-run` shows a semantic diff; a failed validation leaves zero partial output.

```bash
mix starter.gen.slice Project title:string status:enum:draft,active,done \
  --owned-by user --web --api
```

**Why it ranks first:** The template's real product is "an agent ships a green feature fast." Today Notes is the *only* worked recipe, and it must be reproduced by hand every time. A compiler converts the kit from example code into repeatable feature machinery — every future feature becomes faster, more uniform, and easier to review. This is the one idea that multiplies all the others.

**Why pragmatic:** `igniter` already ships as a dev dependency and provides AST-aware, diff-first generators; the birth pipeline already codifies copy/rename/prune/verify. The fixed policy presets (user-owned, authenticated, public-read, admin-managed) and controller/page patterns are already owned by Notes. This prints known-good code; it is not a low-code framework.

**Grounding / honest prerequisites:** This idea is only as good as what it emits into. Ideas **#3** (typed contract) and **#4** (app shell + component set) are effectively prerequisites — without them the compiler emits handwritten drift-prone types into pages that hand-roll their own nav and lack a Textarea/Select/etc. The prior passes ranked the compiler #1 but under-stated this dependency. Build the contract and the shell first, then the compiler emits into a real foundation.

**Boundary:** A deliberate, finite set of field types, relationship kinds, and authorization presets in v1. It prints code; it does not become a generic runtime.

### 2. Unblock the agent loop: `mix starter.admin` + first-class auth test/e2e helpers

**What:** Two tiny, tightly related pieces that remove the most acute day-one friction:

- `mix starter.admin promote user@example.com` / `mix starter.admin create user@example.com` (and a non-empty, idempotent `seeds.exs` that provisions a dev admin from env) so there is always a way *in*.
- A `ConnCase` helper (`register_and_sign_in/1`, `log_in_user/2`) and a Playwright helper (`sign_in/2`) shipped as first-class kit utilities, so authenticated tests are one line instead of a hand-wired sign-in ceremony.

**Why it ranks second:** This is the highest pragmatism-per-line idea in the whole pool and it is the strongest *divergent* find — neither prior pass ranked it. It targets the literal inner loop the template exists to serve. Right now an agent that generates an admin-gated page cannot log in to verify it without editing Postgres by hand, and every authenticated test it writes re-implements sign-in. Fixing both is a handful of lines and pays off on *every* subsequent feature and test.

**Why pragmatic:** The actions already exist (`register_with_password`, `sign_in_with_password`, `Helpers.store_in_session`); `confirmed_user/1` already exists in `test/support/generators.ex`. This is glue and a mix task, not new architecture.

**Grounding:** `priv/repo/seeds.exs` is stock boilerplate (empty); `test/support/conn_case.ex` provides only sandbox setup and `errors_on/1`; `test/e2e/notes_test.exs` seeds and signs in inline.

**Boundary:** Dev/test convenience only. The mix task refuses to run against `MIX_ENV=prod` without an explicit confirmation flag; the seeded admin is env-driven, never a hardcoded credential.

### 3. Generated Ash → TypeScript contract + shared error codec

**What:** Generate frontend contracts from the Ash public surface: resource output types, action input types, pagination/relationship result types, stable machine-readable error types, and one shared **Ash `Invalid` → field-error codec** consumed by *both* the Inertia and JSON:API surfaces. Optional Zod schemas for client validation. Generated files are committed and reproducible; `mix precommit` fails when regeneration would change them.

**Why it ranks third:** This kills the single largest class of agent bug — props and error shapes drifting between Elixir and React — and it collapses the dual-flavor kit into *one contract, two transports*. It is also a hard prerequisite for the compiler (#1) to emit typed pages.

**Why pragmatic:** Ash exposes a normalized public-surface manifest intended for exactly this; `AshTypescript` already generates types, Zod schemas, and typed clients with compile-time verification. One mapper module plus a generated TS package; no new runtime.

**Grounding:** `assets/js/types/*.ts` are handwritten and kept aligned "by discipline" (the files and `assets/js/AGENTS.md` say so). There is no shared error mapper — each field is wired to `form.errors.<name>` individually.

**Boundary:** Keep the existing Inertia and JSON:API transports; do not add a parallel RPC surface by default.

### 4. The frontend foundation: persistent app shell, real dark mode, toasts, and a complete primitive set

**What:** The structural UI layer the template is missing, as one coherent foundation:

- A persistent Inertia layout + app shell (shared header/nav, content region, a single mounted `<Flash>`/toast outlet) instead of every page re-implementing chrome.
- Finish the **already-built** dark mode: a theme provider that applies `.dark`, respects `matchMedia`, persists to `localStorage`, and a toggle in the shell.
- A real toast system (sonner) replacing the static inline flash banner.
- Fill the shadcn primitive gaps the kit already needs (Textarea — currently hand-rolled — plus Select, Dropdown, Popover, Tooltip, Sheet, Badge, Skeleton, Alert), and remove the dead ones.

**Why it ranks fourth (above the credential cockpit):** This is where the kit is weakest on *compelling / intuitive / user-friendly*, and both prior passes systematically under-served it — they scattered these as "pure polish" rejects. But the code shows they are **structural gaps, not polish**: there is no shell at all, and dark mode is 90% implemented with only the switch missing. It also multiplies #1 and #3 (the compiler needs a shell and components to emit into). Where value ties with the cockpit (#6), the tie breaks here on novelty and on this being a prerequisite rather than a leaf feature.

**Why pragmatic:** The dark palette and `dark:` variants already exist — this is a provider and a class toggle, not a re-theme. sonner and the missing shadcn primitives are vendored components, not architecture. Removing dead code (`ui/form.tsx`, unused `zod`/`@hookform/resolvers`/`react-hook-form`) is subtraction.

**Grounding:** `app.tsx` mounts pages with zero wrapping providers; `home.tsx` has an absolutely-positioned bespoke `<nav>`; the CSS carries `--sidebar-*` tokens with no sidebar; `form.tsx` hand-rolls a `<textarea>`; `ui/form.tsx` and the hookform deps are imported nowhere.

**Boundary:** A shell and a component set, not a design-system project. No server-driven UI language.

### 5. `mix starter.check` — the template-integrity / invariant compiler

**What:** Generalize the existing one-off invariant test into a family of high-confidence static checks, run inside `mix precommit` with human output and `--json` for agents:

- Every externally exposed resource carries an authorizer; every exposed action has an applicable policy; sensitive fields never become public.
- Generated TS and OpenAPI remain in sync with the Ash surface.
- **Prune integrity:** every `PRUNE:WEB` block is balanced, and no marker/residue survives in *any* tree — closing the birth-matrix blind spot that today skips `test/` and most of `assets/`.
- Paginated sorts have supporting indexes; generated files contain no unresolved placeholders.

Its natural CI siblings: an **OpenAPI golden snapshot** (fail when `/api/v1` shape drifts) and a **Docker boot smoke** (the release image is built in CI but never run).

**Why it ranks fifth:** The one property that makes this repo valuable is "always green, and prunes clean into either flavor." The code map shows that property is under-protected: residue matching is line-based and fragile, the `--api` residue grep skips `test/`+`assets/`, and the release artifact is never actually booted. A regression here silently poisons *every* future newborn — so guarding the invariant outranks adding another product feature. This overlaps sol-max's invariant compiler, but pushes it specifically toward *template integrity* (prune residue, docker boot), which neither prior pass emphasized.

**Why pragmatic:** `test/starter_kit/api_authorizer_invariant_test.exs` already proves the pattern (pure introspection over `:ash_domains`). `Ash.Info.Manifest` supplies the normalized surface; the prune checks are string/AST scans over files the birth script already walks.

**Boundary:** Only enforce high-confidence rules; support narrow, reasoned suppressions. No style opinions dressed as correctness.

---

## Next 10 (#6–#15)

**6. Credential cockpit + capability-scoped API keys.** Turn `/settings` into a security center: list/revoke active sessions, logout-everywhere, self-service API keys with scopes (`notes:read`, `notes:write`) enforced in Ash policies, show-secret-once, last-used metadata. *Excellent and high-trust — ranked here, not top-5, only because both prior passes already specify it in depth.* It requires concrete modeling fixes first (see Pre-existing issues): `ApiKey`/`Token` need code interfaces, and `Token` needs a `belongs_to :user` (or a subject-query interface) before "list my sessions" is even expressible.

**7. Unified doctor + health/readiness contract.** One check registry behind `mix starter.doctor` (+`--json`), `/health/live`, `/health/ready`, and a Docker `HEALTHCHECK`. Covers runtime versions, env schema, DB/pool, migration + snapshot drift, Oban, asset manifest, mailer probe, token-signing config, admin availability. Public routes return status + safe component names only; every check is timeout-bounded. `config/runtime.exs` already fails fast on missing env; this unifies the rest so probes, CLI, and Docker can't drift.

**8. API reliability envelope.** Give `/api/v1` one production contract: `Idempotency-Key` on mutating requests (actor+method+route+request-hash, DB-uniqueness decides the winner, replay with different input fails explicitly), stable machine-readable error codes, request-id in every response, credential/IP rate limiting with `Retry-After`, optimistic concurrency via `If-Match`/version, and keyset pagination links. Ash already supplies stable keyset pagination; Postgres+Oban supply durable storage and cleanup.

**9. User-visible async Operation framework.** An owner-scoped `Operation` resource (`queued/running/succeeded/failed/cancelled`) with progress, safe result metadata, stable error code, retry/cancel actions, an Oban worker helper, an Inertia progress component (polling or deferred props), and a JSON:API status endpoint. Worked example: CSV import/export. Turns the placeholder `ExampleWorker` into real product behavior every app eventually needs.

**10. Universal data workbench — and upgrade the demo to teach it.** Reusable Ash/Inertia list primitives: URL-backed search/filter/sort, keyset pagination, column visibility, policy-aware bulk actions, CSV export, saved views, and proper empty/loading/error states. Critically, **upgrade the Notes demo to use them** — today the pattern corpus a newborn copies has no pagination, search, or sort, so it teaches the wrong habits. Same read action feeds Inertia and JSON:API.

**11. Durable audit/event ledger + signed webhooks.** For selected actions, append immutable versioned events in the same transaction as the state change (actor, tenant, resource, record, request-id, allowlisted payload). After commit, Oban fans events into HMAC-signed webhook deliveries with retry/backoff, dead-letter, and manual replay; the same ledger powers a searchable AshAdmin audit timeline. Not event sourcing — tables stay the source of truth. `AshEvents` + `AshPaperTrail` demonstrate the pattern; Oban supplies the delivery machinery.

**12. Ash notifier → PubSub → Inertia live-refresh pattern.** A worked recipe for the dual-stack superpower that is currently unused: an `Ash.Notifier.PubSub` on a resource broadcasts on change; a thin channel (or Inertia poll-on-signal) triggers a partial reload so the React list updates live. `Phoenix.PubSub` is already supervised and used only by LiveDashboard today. Ranked as a top-15 pattern (both prior passes filed it as a reject) because it leverages infrastructure already in the box and is the clearest "this feels alive" win.

**13. Soft-delete + trash/restore + cascade correctness.** An `AshArchival`-style soft-delete with a trash/restore UX, plus fixing the currently-undefined user-destroy cascade (`Note.user`/`ApiKey.user` are `allow_nil? false` with no resource-level `on_delete`; the `expire_unconfirmed_users` trigger hard-deletes). Both a real robustness fix and a broadly reusable product pattern.

**14. Organizations / tenancy capability pack.** A removable pack: `Organization`, `Membership` with roles, email invitations (Oban + mailer), current-tenant selection, actor/tenant context, and policy tests — using Ash **attribute** multitenancy (simpler than schema-per-tenant). The whole RBAC surface today is a single server-set `admin?` boolean; almost every real app outgrows single-user ownership immediately.

**15. Frontend quality gate + hygiene.** Bring the frontend up to the backend's bar: ESLint + Prettier + a JS test runner (vitest) wired into `precommit`, `npm audit` folded into the audit step, and removal of the dead deps/files (`zod`, `@hookform/resolvers`, `react-hook-form`, `ui/form.tsx`). Today `assets/package.json` has only `typecheck` + `build`, React components have zero unit tests, and frontend deps are unaudited.

---

## Honorable mentions (strong, not top 15)

| Idea | Why strong | Why not top 15 |
| --- | --- | --- |
| OAuth (Google/GitHub) via AshAuthentication + Inertia interstitial | High demand | Valuable commodity, not a step-function; needs an Identity spike |
| 2FA / TOTP | Trust upgrade | Pairs with the cockpit; sequence it after scoped keys |
| Generated typed API client from OpenAPI (self-dogfood) | Closes the loop with #3 | Depends on #3; smaller marginal win once the contract exists |
| `dotenvy` loader so `.env.example` actually loads | Removes real dev friction | One-liner DX; folds into #7's env story |
| Devcontainer + `docker-compose` Postgres | One-command local env | Onboarding-only; no host env captured today |
| `lefthook` git hook installing `mix precommit` | Enforces the gate locally | DX-only; the gate already exists as an alias |
| Feature flags (Ash resource + plug + Inertia shared prop) | High leverage, small | Good, but less step-function than the top set |
| File uploads (S3/local) as an Ash attachment pattern | Common product need | Commodity; good as a later capability pack |
| Full-text search (Postgres `tsvector`) | Common product need | Narrower; pairs with the workbench |
| GDPR export + account-deletion cascade pack | Trust/compliance | Depends on soft-delete/cascade (#13) and audit (#11) |
| Request-id correlation into logs + Inertia + errors | Cheap observability | `Plug.RequestId` exists but isn't propagated; small |
| Coverage tooling (ExCoveralls) with a gate threshold | Quality signal | Metric-only; no behavior change |
| `ErrorHTML` + client error boundary + 404/500 pages | Robustness/polish | HTML errors fall back to Phoenix defaults today; low urgency |
| Opt-in MCP tool bridge from Ash code interfaces | 2026 differentiator | Depends on scoped keys (#6); narrow first version |

## Explicitly rejected (agree with prior passes)

Multi-region / active-active · offline-first sync (CRDT notes) · full billing platform as core kit · GraphQL as a second public API beside JSON:API · SCIM / LDAP directory · full CQRS + event store · natural-language query over the DB · a product LiveView UI (contradicts the Inertia direction).

---

## Convergence & divergence vs the grok and sol-max passes

Where this pass **converges** (independent agreement is a strong signal to build these): the slice compiler (both had it #1), the Ash→TS contract (both #2), the credential cockpit + scoped keys, the doctor/health contract, the async Operation framework, the API reliability/idempotency envelope, the invariant compiler, the audit/events/webhooks ledger, the data workbench, and organizations/tenancy.

Where this pass **diverges** — the new coverage it contributes:

| This pass | grok | sol-max | Contribution |
| --- | --- | --- | --- |
| #2 Admin bootstrap (`mix starter.admin` + seeds) | — | — | **Novel.** Removes a blocking day-one gap; neither pass raised it |
| #2 First-class auth test/e2e helpers | pool #13 (unranked, Playwright only) | — | **Near-novel.** Adds the `ConnCase` ExUnit helper; ranks it |
| #4 Frontend foundation as *structural*, not polish | pool #61–72 (rejected as polish) | — | **Reframed.** Shell + real dark mode + toasts as a prerequisite tier |
| #5 Prune-residue linter + Docker boot smoke | — | invariant compiler #7 (no prune/docker) | **Extended.** Pushes the invariant tool toward template integrity |
| #6 Email-change / resend-confirm completion | — | — | **Novel.** A real auth hole (`monitor_fields` vs `confirm_on_update? false`) |
| #6 `ApiKey`/`Token` code interfaces + `Token↔User` | — | — | **Novel.** The concrete modeling blocker under the cockpit |
| #12 Ash-notifier → PubSub → Inertia live pattern | honorable reject | — | **Promoted.** Leverages already-supervised PubSub |
| #13 Soft-delete + user-destroy cascade correctness | pool #39 (unranked) | — | **Ranked + fixes a real cascade gap** |
| #15 Frontend quality gate + dead-dep removal | — | — | **Novel.** ESLint/Prettier/vitest + subtraction |

The through-line of the divergence: grok and sol-max both optimized for *features a born app will want* (cockpit, webhooks, tenancy, workbench). This pass optimizes harder for *the template's own product* — the birth + agent + always-green loop — and for finishing the things that are already 90% built (dark mode, the auth surface, the component set), which is where the cheapest high-leverage wins actually live.

---

## Pre-existing issues surfaced (fix candidates)

The code map turned up latent issues worth fixing independently of any feature above. Flagged here rather than silently fixed, because this task was scoped to ideation:

- **Email-change flow is a hole.** `User` sets `monitor_fields [:email]` (implying reconfirmation on change) but `confirm_on_update? false` and no action accepts `:email` — so there is no email-change path and no resend-confirmation interface. Either wire the reconfirm-on-change flow or drop the misleading `monitor_fields`.
- **`ApiKey` exposes zero code interfaces.** A user cannot list/create/revoke their own keys through the domain; callers must use raw `Ash.create`. Same for `Token`.
- **`Token` has no `belongs_to :user`.** It is coupled to users only by the `subject` string, so per-user session/token queries and aggregates aren't expressible in Ash relationships — a blocker for the session-management UI.
- **User destroy has an undefined cascade.** `Note.user`/`ApiKey.user` are `allow_nil? false` with no resource-level `on_delete`; deleting a user (incl. the `expire_unconfirmed_users` trigger) relies entirely on the DB FK.
- **Dead frontend code/deps.** `ui/form.tsx` is imported nowhere; `zod`, `@hookform/resolvers`, and `react-hook-form` are unused (the last only by the dead `ui/form.tsx`).
- **Dark mode is unreachable.** The `.dark` palette and `dark:` variants exist but nothing applies the class — the styling ships but the feature doesn't.
- **CI residue backstop has a blind spot.** The birth-matrix `--api` residue grep omits `test/` and most of `assets/`, leaning entirely on `apply_markers` for those trees; a stray marker there ships silently.
- **`seeds.exs` is empty despite an admin flag + migration.** No admin, no demo login.

---

## Suggested build order (dependency-aware)

1. **Foundation that everything emits into:** #3 typed contract, then #4 frontend shell/components. In parallel, the cheap unblockers: #2 admin bootstrap + auth helpers, and the Pre-existing fixes (`ApiKey`/`Token` interfaces, `Token↔User`, email-change).
2. **Guardrails before generation:** #5 `mix starter.check` (with the prune-residue lint) in `precommit`.
3. **The multiplier:** #1 `mix starter.gen.slice`, now emitting typed pages into a real shell, guarded by the invariant compiler.
4. **User-visible trust:** #6 credential cockpit + scoped keys, #7 doctor/health.
5. **Reliability + platform:** #8 API envelope, #9 async operations, #10 workbench (+ demo upgrade), #11 audit/webhooks, #12 live-refresh, #13 soft-delete.
6. **Versatility:** #14 organizations pack; then honorable-mention packs (OAuth, files, search, GDPR) as demand appears.

This puts the contract + shell + guardrails first so the slice compiler prints typed, guarded, real-looking code — preventing a capability matrix from arriving before the machinery that keeps it green.

## Provenance

Generated 2026-07-16 by Opus 4.8 as a fresh, divergent third pass, grounded in a direct read-through of `lib/`, `assets/`, `bin/`, `test/`, `config/`, and `.github/`. Rankings are opinionated for leverage × pragmatism × novelty. Not a commitment to implement; a companion to the grok and sol-max passes, deliberately weighted toward the coverage they left open.

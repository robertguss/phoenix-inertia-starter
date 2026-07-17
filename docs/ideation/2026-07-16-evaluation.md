# Ideation Evaluation — Verdicts Across All Four Passes

**Date:** 2026-07-16
**Status:** Evaluation and prioritization; not an implementation commitment
**Inputs:** the four sibling ideation docs — [grok](./2026-07-16-powerful-functionality-ideas.md), [sol-max](./2026-07-16-top-10-powerful-functionality-ideas.md), [opus](./2026-07-16-opus-ideas.md), [fable](./2026-07-16-fable-ideas.md) — plus a full independent read of the codebase.

## Evaluation criteria

Set with the template owner before evaluating:

1. **Audience: both** — personal project factory first, but public and adoptable. Ideas must not bloat the template into a product, and must not embarrass it publicly (missing lint, dead deps).
2. **Birthed projects: mixed/general** — side projects, tools, APIs, sometimes SaaS. Universal foundations beat vertical features. SaaS-shaped features (billing, orgs) only qualify as opt-in packs or recipes, never core.
3. **Delivery judged per idea** — in-the-box (prunable like the demo), birth flag, or recipe/pack docs.
4. **The template's standing constraints** — pinned, always-green, agent-legible. Every in-box feature is a permanent maintenance liability across every future dependency refresh. The cheapest code is code the Ash ecosystem already maintains.

One more lens the idea docs mostly lack: **a template feature is only worth shipping if most newborns would otherwise build it worse**. Features most newborns won't use fail this test no matter how well-designed.

## Grounding verification

The opus doc makes concrete "pre-existing gap" claims the others don't. All verified true against the code before ranking:

- `priv/repo/seeds.exs` is stock boilerplate — no admin bootstrap despite `admin?` flag + migration existing.
- Dark palette exists only in `assets/css/app.css`; nothing ever applies `.dark` (no provider, toggle, or persistence).
- `zod`, `react-hook-form`, `@hookform/resolvers` are referenced only by `assets/js/components/ui/form.tsx`, which nothing imports. Dead.
- `Token` has no `belongs_to :user` — per-user session queries not expressible.
- `test/support/conn_case.ex` has no auth helpers; every authed test hand-wires sign-in.
- `User` has `monitor_fields [:email]` with `confirm_on_update? false` and no action accepting `:email` — no email-change path exists and the config is self-contradictory.
- `ApiKey` is registered in the domain with zero code interfaces.

The convergence signal is also real: four independent passes ranked the **slice generator** and the **Ash→TypeScript contract** in their top 3. That is the strongest evidence in these documents.

---

## Verdicts

Effort scale matches the fable doc: **S** ≈ a day, **M** ≈ 2–4 days, **L** ≈ a week.

### Tier 0 — Fix first (before any feature work)

These aren't features; they're debts and 90%-built stubs. All cheap, all high-leverage, and several are hard prerequisites for the tiers below. Only the opus pass caught most of these — its single biggest contribution.

| Fix | Source | Effort | Verdict reasoning |
|---|---|---|---|
| **Admin bootstrap** — idempotent `seeds.exs` dev admin from env + `mix starter.admin promote/create` (refuses prod without confirm flag) | opus #2 | S | An agent shipping an admin-gated feature literally cannot log in to see it today. Highest pragmatism-per-line item in all four docs. |
| **Auth test helpers** — `register_and_sign_in/1`, `log_in_user/2` in ConnCase; `sign_in/2` Playwright helper | opus #2 | S | Every authed test hand-wires sign-in — exactly where agents write the most redundant code. Glue over existing actions. |
| **Auth modeling fixes** — `ApiKey`/`Token` code interfaces, `Token belongs_to :user`, resolve the email-change contradiction (wire reconfirm-on-change or drop `monitor_fields`), define user-destroy cascade | opus issues list | S–M | Real holes, not features. Blockers for the credential cockpit (Tier 3). The email-change config is actively misleading to agents reading the code as a pattern corpus. |
| **Finish dark mode** — theme provider applying `.dark`, `matchMedia` default, localStorage persistence, toggle | opus #4 (part) | S | The palette and `dark:` variants are already written and shipped. Shipping styling without the switch is the worst of both worlds: full maintenance cost, zero user value. |
| **Dead code removal** — delete `ui/form.tsx`; drop `react-hook-form` + `@hookform/resolvers`; keep `zod` *only* if the codegen (Tier 1) emits Zod schemas, else drop it too | opus #15 (part) | S | Unused deps in a public template teach agents wrong patterns and rot on every refresh. Subtraction is free maintenance. |
| **Prune-integrity hardening** — balanced-marker lint (unbalanced `PRUNE:WEB` currently skips silently to EOF), widen `--api` residue grep to `test/` + `assets/` | opus #5 (part) | S | The birth/prune pipeline *is* the product. A silent prune bug poisons every future newborn. Cheapest insurance in the whole list. |

### Tier 1 — Build now (core foundations)

**1. Ash→TypeScript contract (`mix starter.codegen`)** — grok #2, sol-max #2, opus #3, fable #1. **Verdict: build. Effort M. In-box.**
The untyped seam between Ash and React is the template's deepest structural weakness, and Ash resources being introspectable data makes this uniquely cheap here. Four-way consensus at top-3 settles the "what"; scope is the judgment call:

- v1: resource output types, `SharedProps`, and the shared Ash `Invalid` → field-error codec (the error codec is what kills the biggest agent-bug class, and it benefits *both* flavors).
- Zod schemas if near-free from constraint mapping (this is what justifies keeping `zod`).
- Route helpers (fable's Ziggy-style idea) are good but v1.1 — smaller bug class, separable.
- `--check` mode joins `mix precommit` beside `generate_migrations --check`, so drift fails the gate. This is the piece that makes it template-grade rather than a convenience.
- Evaluate `AshTypescript` first (sol-max's pointer): if it fits the Inertia shape without dragging in its RPC surface, riding a maintained package beats owning a generator. If it doesn't fit cleanly, a small custom emitter over `Ash.Resource.Info` is fine — the introspection API is stable.

**2. Frontend foundation — persistent app shell, toasts, missing primitives** — opus #4 (grok filed these as "polish" rejects; opus is right that they're structural). **Verdict: build. Effort S–M. In-box.**
There is no shell: every page rolls its own nav and flash handling, so everything the generator (Tier 2) would emit lands in chrome-less pages, and every newborn rebuilds the same layout on day one. A persistent Inertia layout + single toast outlet (sonner) + the missing primitives the kit already needs (Textarea is currently hand-rolled; Select, Dropdown, Badge, Skeleton, Alert) is a bounded, one-time job. Not a design system — a floor.

**3. Pagination + data-table kit, demo upgraded to teach it** — fable #5, opus #10, sol-max #9, grok pool. **Verdict: build the modest version. Effort M. In-box.**
Every app built from this template will render filterable lists, Ash already implements the server half (pagination, sorting, filtering — currently switched on nowhere, including the demo agents copy), and URL-state table mechanics are tedious to get right. Ship: pagination on list actions, a `paginate_params/1` controller helper, `useTable()` + `<DataTable>` with sort/search/pagination/empty states, Notes index converted so the pattern corpus teaches it.
Explicitly **cut from v1** (sol-max's "workbench" scope): saved views, column visibility, CSV export, bulk actions, deferred aggregates. That's a product feature set, not a template floor — add by demand.

**4. Template integrity checks (`mix starter.check`, modest)** — sol-max #7, opus #5. **Verdict: build the narrow version. Effort S–M. In-box.**
Extend the pattern `api_authorizer_invariant_test` already proves: every exposed resource policy-gated, sensitive fields never public, codegen/OpenAPI drift, prune integrity (Tier 0's lint folded in), no unresolved placeholders. Plus the two CI gaps opus found: an OpenAPI golden snapshot and a Docker boot smoke (the release image is built in CI but never booted).
Skip the "invariant compiler" framing — no rule DSL, no suppression system until a real need appears. A test module with good failure messages is the lazy correct form.

### Tier 2 — The multiplier

**5. Vertical slice generator (`mix starter.gen.slice`)** — grok #1, sol-max #1, opus #1, fable #2. **Verdict: build, but after Tier 1. Effort L. In-box (dev-only).**
The only idea all four passes ranked #1–2, and the reasoning holds: the template's product is "agent ships a green feature fast," Notes is the only recipe, and a generator converts convention-by-example into convention-by-construction. Igniter is already a dev dep; `bin/remove_demo` already proves slices are a first-class unit.
Two disciplines keep it honest:

- **Sequence:** opus's dependency argument is correct and the other two passes under-weighted it — built first, the generator emits untyped pages into chrome-less scaffolding. Contract + shell + integrity checks first, then the generator prints into a real foundation.
- **Scope:** v1 is a fixed menu — scalar field types, `--owned-by user` preset (+ `authenticated`/`public-read`/`admin-managed`), `--web`/`--api` surfaces, full test spread, `--dry-run`. No relationships beyond owner in v1, no nested resources, no low-code drift. It prints known-good code; the demo slice is its golden fixture in CI.

This is also the gate for several deferred ideas: once slices are generated, options like `--archival` or a tenancy pack become printable instead of hand-maintained.

### Tier 3 — Worth building, staged behind the core

**6. Credential cockpit (sessions + API-key management UI)** — grok #8, sol-max #3, opus #6, fable #6 (part). **Verdict: build after Tier 0 modeling fixes. Effort M. In-box.**
Four-way convergence, and the machinery genuinely exists (`store_all_tokens? true`, revocation actions, one-time plaintext). Mostly UI over data already kept — but only *after* Tier 0 gives `Token`/`ApiKey` interfaces and the user relationship; today "list my sessions" isn't even expressible. Universal across mixed/general projects (every app has an account page), unlike most SaaS-shaped ideas.

**7. Scoped API keys** — grok #3, sol-max #3, opus #6. **Verdict: build small, with or after the cockpit. Effort S–M. In-box.**
A scopes array on the key checked in policies is a real least-privilege upgrade for the API flavor at small cost. Keep v1 to static scope strings (`notes:read`); no scope-hierarchy machinery.

**8. Can-props (policy-aware UI)** — fable #4 only. **Verdict: build. Effort S. In-box.**
Best value-per-line in the fable doc and no other pass saw it: a ~50-line `Ash.can?/3` serializer helper + generated `can` types eliminates UI/authz drift as a bug class, using the policy engine that already runs. Opt-in per call site keeps it off hot paths. Cheap, differentiating, teaches the right habit.

**9. Live props (PubSub → Inertia partial reload)** — fable #3, opus #12, grok pool. **Verdict: build after Tier 1. Effort M. In-box (inside `PRUNE:WEB`).**
Answers the sharpest anti-Inertia criticism ("you gave up real-time") with ~150 lines riding infrastructure already supervised, and the reload path reuses the normal controller/policy/serializer cycle so nothing can drift. Genuinely differentiating — almost no Inertia starter anywhere has it, and BEAM is the ecosystem best placed to. Not Tier 1 only because nothing else depends on it (fable's notification bus that would consume it is deferred below).

**10. Error visibility** — fable #9 (custom "Error Inbox"). **Verdict: goal yes, custom build no — integrate the `error_tracker` hex package instead. Effort S.**
Fable's diagnosis is right (newborns need zero-service error tracking; the React error-boundary half genuinely lacks coverage) but the prescription re-invents a maintained wheel: `error_tracker` already does Postgres-backed capture, grouping, occurrence counts, and a dashboard UI, self-hosted, no external service. Mount it behind the existing admin gate, add the small CSRF-exempt client-error endpoint + React `ErrorBoundary` for the frontend half, prune old events. Owning a bespoke ErrorEvent pipeline in a pinned template is permanent maintenance for commodity function.

**11. Health endpoints, then doctor** — sol-max #4, opus #7. **Verdict: split it. `/health/live` + `/health/ready` + Docker `HEALTHCHECK` now (S, in-box); the full `mix starter.doctor` check registry later (M, nice-to-have).**
Probes are ~30 lines, every deploy target wants them, and the release image gets a real healthcheck. The unified doctor registry is good DX but pure DX — it can wait until the check list stops changing.

**12. Frontend quality gate** — opus #15. **Verdict: build. Effort S–M. In-box.**
ESLint + Prettier + a vitest smoke + `npm audit` folded into precommit. The backend gate is seven tools deep while the frontend has `tsc` only — for a public template claiming "always-green," that asymmetry is a credibility gap. Bounded, boring, done once.

### Tier 4 — Real value, wrong delivery for core: recipes and packs

These fail the "most newborns need it" test for a mixed/general template, but are strong on-demand additions. Deliver as recipe docs now; graduate to `mix starter.add` packs only after the generator (Tier 2) exists and at least one pack has been built by hand.

- **Organizations/tenancy** — grok #4, sol-max #10, opus #14; fable cut it, correctly. It re-architects every resource, policy, and page; as core it would double template complexity for the subset of newborns that are actually multi-tenant. First and most-demanded pack, attribute tenancy, after the generator.
- **OAuth (Google/GitHub)** — fable #6; honorable-mention elsewhere. Mostly AshAuthentication config + a `UserIdentity` resource, but needs provider apps/keys and can't be meaningfully exercised by the gate. Recipe.
- **TOTP 2FA + sudo mode** — fable #6. Good, security-sensitive, pairs with the cockpit. Pack/recipe after cockpit ships; sudo-mode plug is small enough to fold into cockpit v1.1.
- **Idempotency keys + full API reliability envelope** — grok #6, sol-max #6, opus #8. Split: stable machine-readable error codes + request-id propagation are cheap and belong in-box with the error codec (Tier 1). Idempotency storage, `If-Match` concurrency, and rate-limit headers are integration-platform features most mixed newborns never hit — recipe for the API flavor. One exception worth in-box: brute-force throttling on the auth endpoints (small `hammer` plug) — that's security baseline, not reliability polish.
- **Soft delete/archival + undo + paper_trail** — fable #8, opus #13. `ash_archival`/`ash_paper_trail` make it nearly config, and fable's undo-toast UX is genuinely nice — but silently filtered reads are a behavioral opinion not every app wants, and defaults in a template are load-bearing. Recipe now; `--archival` generator flag later. The undefined user-destroy cascade portion is Tier 0, independent of this.
- **Audit ledger + signed webhooks** — grok #5/#9, sol-max #8, opus #11. The full transactional-outbox + HMAC delivery + replay machine is platform infrastructure for apps with partners — a minority of mixed newborns, and a big maintenance surface (delivery states, dead-letter, replay UI). Pack, by demand. Basic audit needs are covered far cheaper by `ash_paper_trail` in the archival recipe.
- **Async Operation framework** — sol-max #5, opus #9. Both passes overrate it. A generic owner-scoped Operation resource + progress protocol + UI components is a framework, with framework maintenance, for a need (user-visible imports/exports/long jobs) that's real but not universal, and that Oban + a small worked example mostly covers. Recipe with a worked CSV-export example; extract a shared resource only if repeated use proves the shape.
- **AI slice (`ash_ai` + streaming chat)** — fable #10, grok #10 (MCP bridge variant). "AI-ready" demand is real and the Ash-actions framing is the right one — but `ash_ai` and the provider APIs under it are the fastest-moving deps in the ecosystem, which collides directly with pinned/always-green. A template whose gate breaks on every provider-SDK shift loses its identity. Recipe (with Mimic-mocked tests shown), revisit as a pack when the dep stabilizes. MCP bridge folds into this; not a standalone top-10 item.

### Skip

- **Policy oracle CLI (`mix starter.can`)** — grok #7. Marginal: `Ash.can?/3` in IEx, Ash's built-in policy-breakdown logging, and Tidewave (already shipped for agents) cover the debugging story. A page in `AGENTS.md` documenting those beats owning a tool. Can-props (Tier 3) delivers the user-facing half properly.
- **Capability-pack manifest system** — sol-max #10's framing. Framework before content: zero packs exist. Build organizations by hand as the first pack, extract the manifest machinery when a second pack proves the pattern. (Fable and opus both independently reached this conclusion; they're right.)
- **Notifications framework** — fable #7. Well-designed, but in-app notification centers are product furniture, not template floor — plenty of mixed/general newborns (APIs, tools) have zero use for a bell icon, and it drags email-digest scheduling and preference UI along. Pack later, after live props exists to carry it.
- **The docs' own reject lists** — multi-region, offline-first/CRDT, billing-as-core, GraphQL second API, SCIM/LDAP, full CQRS/event-store, NL-over-SQL, product LiveView UI. All four passes agree; so does this evaluation. Also staying skipped from the pools: SSR/SEO kit (adds a Node runtime to deploys for mostly-behind-login apps), command palette, i18n, presence, PWA shell, Storybook — real features, wrong template.

---

## Where this evaluation disagrees with the docs

- **grok/sol-max build orders start with product features** (cockpit/scoped keys first for grok; contract → invariants → compiler is sol-max's, which is close). Neither noticed the Tier 0 debts. Opus's dependency-aware order is the closest to correct and this evaluation largely adopts it.
- **grok filed the frontend foundation under "pure polish" rejects.** Opus's reframe is verified correct: no shell exists at all and dark mode is shipped-but-unreachable. Those are structural gaps.
- **sol-max #5 (Operation framework) and #8 (event ledger + webhooks) are overranked** for a mixed/general template — both are platform infrastructure serving a minority of newborns, ranked above things every newborn touches (tables, shell).
- **fable #9 (error inbox) has the right goal and the wrong build** — integrate `error_tracker` rather than owning a bespoke pipeline.
- **fable is the only pass that correctly cut tenancy from its top 10** while the other two ranked it; for a mixed/general audience fable's call stands.
- **opus #2 (admin bootstrap + auth helpers) is the most underrated idea across all four docs** — only one pass found it, it costs a day, and it unblocks the exact loop the template exists to serve.

## Recommended sequence

1. **Tier 0 sweep** (≈ a week total): admin bootstrap, test helpers, auth modeling fixes, dark-mode finish, dead-code removal, prune-integrity hardening. Every later tier gets cheaper.
2. **Tier 1:** TS contract → frontend shell → pagination/table + demo upgrade → `starter.check` (modest) + CI snapshot/boot-smoke.
3. **Tier 2:** the slice generator, emitting typed pages into the real shell, guarded by the checks.
4. **Tier 3 trust batch:** credential cockpit + scoped keys → can-props → live props → error_tracker + health endpoints → frontend gate (can start anytime; independent).
5. **Tier 4 by demand:** write recipes (OAuth, archival, idempotency, operations, AI); build the organizations pack first when a real project needs it, then extract pack machinery.

## Verdict summary

| Idea | Consensus | Verdict | Effort | Delivery |
|---|---|---|---|---|
| Admin bootstrap + auth test helpers | opus only | **Build first** | S | In-box |
| Auth modeling fixes (ApiKey/Token/email/cascade) | opus only | **Build first** | S–M | In-box |
| Dark mode finish + dead-code removal | opus only | **Build first** | S | In-box |
| Prune-integrity hardening | opus only | **Build first** | S | In-box |
| Ash→TS contract + error codec | 4/4 top-3 | **Build** | M | In-box, gate-checked |
| App shell + toasts + primitives | opus (grok rejected) | **Build** | S–M | In-box |
| Pagination + data-table (modest) | 3/4 | **Build** | M | In-box |
| `starter.check` (modest) + CI gaps | 2/4 | **Build** | S–M | In-box |
| Slice generator | 4/4 #1–2 | **Build after Tier 1** | L | In-box (dev) |
| Credential cockpit | 4/4 | **Build** | M | In-box |
| Scoped API keys | 3/4 | **Build small** | S–M | In-box |
| Can-props | fable only | **Build** | S | In-box |
| Live props | 2.5/4 | **Build** | M | In-box (web) |
| Error tracking | fable only | **Build via `error_tracker` pkg** | S | In-box |
| Health probes | 2/4 | **Build** (doctor later) | S | In-box |
| Frontend quality gate | opus only | **Build** | S–M | In-box |
| Auth brute-force throttle | (part of API envelope) | **Build** | S | In-box |
| Organizations/tenancy | 3/4 ranked, fable cut | **Later** | L | Pack |
| OAuth / 2FA / sudo | fable ranked | **Later** | M | Recipe/pack |
| Idempotency + API envelope (rest) | 3/4 | **Later** | M | Recipe (API flavor) |
| Archival + undo + paper_trail | 2.5/4 | **Later** | S–M | Recipe → generator flag |
| Audit ledger + webhooks | 4/4 mid | **Later** | L | Pack |
| Operation framework | 2/4 | **Later, as recipe not framework** | M | Recipe |
| AI slice / MCP bridge | fable + grok | **Later** | M | Recipe |
| Doctor registry (full) | 2/4 | **Later** | M | In-box eventually |
| Notifications framework | fable only | **Skip for now** | M | Pack, by demand |
| Policy oracle CLI | grok only | **Skip** | S | Document instead |
| Pack-manifest framework | sol-max | **Skip until 2 packs exist** | L | — |
| Docs' joint reject lists | 4/4 | **Skip** | — | — |

# Top 10 Powerful Functionality Ideas

**Date:** 2026-07-16

**Status:** Ideation; not an implementation commitment

**Scope:** High-leverage capabilities that make every generated Phoenix/Ash project more useful, intuitive, versatile, robust, and reliable

This document is a companion to [the full candidate-pool ideation](./2026-07-16-powerful-functionality-ideas.md). That document preserves the broad set of roughly 100 ideas. This document captures the final re-ranked top ten after deeper codebase inspection, feasibility research, and complexity review.

## Ranking method

The review screened 118 candidates. Ideas received hard cuts for weak pragmatism, product lock-in, parallel business layers, new distributed-system requirements, or explosive CI matrices. Remaining ideas were weighted most heavily for usefulness and pragmatism, then reviewed for synergy.

Because this repository is a template rather than a product application, multiplier capabilities rank above isolated product features. Strong ideas should improve many future features, work for agents and human developers, and remain bounded enough to keep newborn projects understandable.

## 1. Vertical-slice compiler: `mix starter.gen.slice`

### Capability

Accept a resource name, fields, ownership model, and target surfaces, then generate a complete conventional feature slice:

- Ash resource, actions, validations, relationships, and policies
- Domain code interfaces
- Migration and resource snapshot
- Inertia controller, pages, forms, and list view for web projects
- AshJsonApi routes and OpenAPI exposure for API projects
- Generated TypeScript contracts
- Ash action, policy, controller, JSON:API, and Playwright tests
- Formatting, code generation, targeted verification, and optional full gate

Example:

```bash
mix starter.gen.slice Project \
  title:string \
  status:enum:draft,active,complete \
  --owned-by user \
  --web \
  --api
```

Command should support `--dry-run`, show a semantic diff, reject unsafe overwrites, and leave no partial output after a failed validation.

### Why it ranks first

Current Notes slice is a strong worked recipe, but developers and agents must reproduce its structure manually. Compiler turns starter from example code into repeatable feature machinery. Every future feature becomes faster, more consistent, and easier to review.

Birth pipeline already codifies copy, rename, prune, and verification in [`bin/new_project`](../../bin/new_project). Igniter already ships as a development dependency in [`mix.exs`](../../mix.exs) and supports composable AST-aware generators that present diffs before applying changes. See [Igniter generator documentation](https://igniter.hexdocs.pm/writing-generators.html).

### Pragmatic boundary

First version should support a deliberate set of field types, relationships, and authorization presets such as user-owned, authenticated, public-read, and admin-managed. It should print known-good code, not become a generic low-code framework.

## 2. Generated Ash-to-TypeScript contract

### Capability

Generate frontend contracts from Ash public surface:

- Resource output types
- Action input and metadata types
- Zod schemas for client validation
- Typed route and path helpers for Inertia controllers
- Pagination and relationship result types
- Stable machine-readable error types
- Shared Ash-to-form error codec used by Inertia and JSON:API surfaces

Generated files should be committed or deterministically reproduced, and `mix precommit` should fail when code generation would change them.

### Why it ranks second

Current frontend types, such as [`assets/js/types/notes.ts`](../../assets/js/types/notes.ts), are handwritten beside independently evolving Ash resources. That creates silent drift, weak refactors, duplicated validation knowledge, and common agent mistakes.

Ash now exposes `Ash.Info.Manifest`, a normalized public-surface representation intended for code generators. AshTypescript already supports generated types, Zod schemas, action clients, validation errors, pagination, typed controllers, and compile-time verification. See [Ash manifest documentation](https://ash.hexdocs.pm/code-generation.html) and [AshTypescript documentation](https://ash-typescript.hexdocs.pm/readme.html).

### Pragmatic boundary

Keep existing Inertia controller and JSON:API transports. Do not add a parallel RPC surface by default. Use AshTypescript selectively for build-time contracts and path helpers unless a born application explicitly chooses RPC.

## 3. Credential cockpit with capability-scoped API keys

### Capability

Turn account settings into a complete security center:

- List active sessions with creation and expiry times
- Identify current session
- Revoke one session or every other session
- Create named API keys with scopes and expiry
- Show key plaintext exactly once
- Record last-used time and safe usage metadata
- Revoke keys immediately
- Show recent credential-security activity
- Optionally accept trusted secret-scanner revocation reports

Example scopes could include `notes:read`, `notes:write`, and `account:read`. Scope enforcement belongs in Ash policy checks so browser, API, background, and future tool surfaces share one authorization model.

### Why it ranks third

Strong credential machinery already exists but remains mostly invisible. [`User`](../../lib/starter_kit/accounts/user.ex) stores every token and requires token presence. [`Token`](../../lib/starter_kit/accounts/token.ex) already supports individual and subject-wide revocation. [`ApiKey`](../../lib/starter_kit/accounts/api_key.ex) already hashes keys, expires them, and exposes plaintext only at creation.

Small schema, action, policy, and UI additions therefore create a large end-user trust upgrade. AshAuthentication's [API-key guide](https://ash-authentication.hexdocs.pm/api-keys.html) confirms hash-only storage and one-time plaintext access.

### Pragmatic boundary

First version should complete existing password, magic-link, session, and API-key capabilities. OAuth, passkeys, and MFA remain separate later decisions.

## 4. Unified production doctor and health contract

### Capability

Define one reusable registry of operational checks and expose it through:

- `mix starter.doctor` for human-readable diagnosis
- `mix starter.doctor --json` for agents and CI
- `/health/live` for process liveness
- `/health/ready` for dependency readiness
- Docker `HEALTHCHECK`

Checks should cover:

- Required runtime versions and executables
- Environment configuration schema
- Database connectivity and pool health
- Applied migrations and Ash snapshot drift
- Oban availability and queue execution
- Production asset manifest
- Mail adapter configuration and safe delivery probe
- Token-signing and cookie-secret configuration
- Initial admin availability
- OpenAPI generation
- CSP compatibility with configured external origins

### Why it ranks fourth

Kit already has fail-fast environment parsing in [`config/runtime.exs`](../../config/runtime.exs) and a useful metric catalog in [`StarterKitWeb.Telemetry`](../../lib/starter_kit_web/telemetry.ex), but no unified operational diagnosis or readiness contract. One check registry prevents CLI, probes, Docker, and deployment documentation from drifting apart.

This produces immediate deployment reliability with limited code and no monitoring-vendor commitment.

### Pragmatic boundary

Public health routes should return only status and safe component names. Detailed errors, secrets, hosts, and stack traces belong only in local CLI output or an authenticated admin surface. Every check needs a strict timeout so readiness never hangs.

## 5. User-visible asynchronous operation framework

### Capability

Add an owner-scoped `Operation` resource with a small state model:

- `queued`
- `running`
- `succeeded`
- `failed`
- `cancelled`

Store operation type, progress, safe result metadata, stable error code, timestamps, actor, and optional idempotency key. Supply:

- Oban worker behavior or helper module
- Progress-update API
- Retry and cancellation actions
- Inertia progress component using polling or deferred props
- JSON:API status endpoint
- Policy and concurrency tests
- Worked CSV import or export example

### Why it ranks fifth

Current [`ExampleWorker`](../../lib/starter_kit/workers/example_worker.ex) proves background execution but not complete product behavior. Real applications quickly need user-visible imports, exports, reports, media processing, AI jobs, and external synchronization.

Reusable operation pattern makes all those features understandable and consistent. Oban already provides retry behavior, cancellation, uniqueness, and telemetry; see [Oban unique-jobs guide](https://oban.hexdocs.pm/unique_jobs.html).

### Pragmatic boundary

Keep one operation lifecycle and one worker integration. Do not build workflow DAGs, distributed orchestration, arbitrary job composition, or a second state-machine platform.

## 6. Action-aware API reliability envelope

### Capability

Give `/api/v1` one consistent production contract:

- `Idempotency-Key` support for mutating requests
- Stable machine-readable error codes
- Request ID in every error and response
- Credential- and IP-aware rate limiting with `Retry-After`
- Optimistic concurrency through a record version or `If-Match`
- Standard keyset pagination and navigation links

Idempotency records should bind actor or credential, method, route, normalized request hash, result identity, status, and expiry. A database uniqueness constraint must decide which concurrent request owns the key. Reusing a key with different input must fail explicitly.

### Why it ranks sixth

These capabilities turn a correct demo API into an integration-safe API. Clients can retry after network failures, avoid lost updates, recover from rate limits predictably, and report failures using stable identifiers.

Ash already provides robust keyset pagination that remains stable while data changes; see [Ash pagination guide](https://ash.hexdocs.pm/ash/pagination.html). Postgres and Oban already provide durable storage and cleanup machinery.

### Pragmatic boundary

Avoid a naïve plug that merely caches raw responses; it leaves race and crash gaps around committed actions. Make idempotency action-aware. Stage delivery with error contract and idempotency first, then optimistic concurrency and rate limiting.

## 7. Starter invariant compiler: `mix starter.check`

### Capability

Generalize project-specific safety knowledge into high-confidence static checks:

- Every externally exposed resource has an authorizer
- Every exposed action has an applicable policy
- Sensitive fields never become public
- User-owned creates establish ownership from actor context
- Web modules use domain code interfaces
- Generated TypeScript and OpenAPI remain synchronized
- Paginated sort patterns have suitable indexes
- Dangerous migrations require explicit acknowledgement
- Flavor and capability pruning leaves no residue
- Generated files contain no unresolved placeholders

Run task inside `mix precommit`, with concise human output and structured JSON for agents.

### Why it ranks seventh

Existing [`api_authorizer_invariant_test.exs`](../../test/starter_kit/api_authorizer_invariant_test.exs) proves value of project-specific invariant tests. Extending that pattern catches mistakes generic Credo, Sobelow, and Dialyzer cannot understand.

`Ash.Info.Manifest` provides normalized public resources, fields, relationships, actions, and multitenancy metadata. Phoenix routes, OpenAPI, migration AST, and feature manifests provide remaining inputs.

### Pragmatic boundary

Only enforce high-confidence rules. Support narrow suppressions with mandatory reasons and locations. Avoid style opinions or brittle scans presented as correctness proofs.

## 8. Durable domain-event ledger, audit timeline, and signed webhooks

### Capability

For selected Ash actions, append immutable versioned events inside the same database transaction as state changes. Event should contain:

- Stable event ID and type
- Schema version
- Actor and tenant identifiers
- Resource and record identifiers
- Request ID
- Allowlisted metadata and payload
- Occurrence time

After commit, Oban should fan selected events into webhook delivery records with HMAC signatures, retry/backoff, dead-letter state, delivery history, and manual replay. Same event ledger should power searchable AshAdmin audit timeline answering who changed what and when.

### Why it ranks eighth

One durable event foundation unlocks support investigations, compliance evidence, partner integrations, activity feeds, and future notifications. Existing Ash actions, Postgres transactions, Oban retries, and AshAdmin remove need for another service.

Ash ecosystem already demonstrates actor-attributed persisted event logs through [AshEvents](https://hexdocs.pm/ash_events/readme.html), while Oban provides [instrumentation and retry primitives](https://oban.hexdocs.pm/instrumentation.html).

### Pragmatic boundary

This is not event sourcing. Current resource tables remain source of truth. Do not rebuild aggregates from events, introduce Kafka, or store unrestricted sensitive changes. Internal audit events and external webhook payloads need separate allowlists and retention rules.

## 9. Universal data workbench

### Capability

Replace bare list pages with reusable Ash/Inertia data-workbench primitives:

- URL-backed search, filters, and sorting
- Keyset pagination
- Column visibility
- Bulk selection and policy-aware actions
- Saved views
- CSV export
- Deferred counts and expensive aggregates
- Empty, loading, error, and partial-success states

Expose configuration per resource and let slice compiler emit a working default. Use same Ash read action and filter definitions for Inertia and JSON:API wherever practical.

### Why it ranks ninth

Current [Notes index](../../assets/js/pages/notes/index.tsx) renders every note into a basic table. Real applications immediately need scalable discovery and manipulation. A polished reusable workbench makes generated features feel substantial without inventing business-specific UI each time.

Ash already supplies filtering, sorting, bulk actions, and keyset pagination. Inertia supports deferred props and partial reloads; see [Inertia deferred-props guide](https://inertiajs.com/docs/v2/data-props/deferred-props).

### Pragmatic boundary

Keep resource configuration explicit and typed. Do not build a server-driven UI language, spreadsheet clone, or generic replacement for AshAdmin.

## 10. Manifest-driven capability packs, organizations first

### Capability

Add machine-readable newborn manifest recording:

- Template version
- Selected flavor
- Enabled capability packs
- Pack versions
- Applied migrations or codemods
- Required environment values

Provide idempotent commands such as:

```bash
mix starter.add organizations
mix starter.add webhooks
mix starter.add archival
```

Commands should preview semantic diffs, validate compatibility, run Ash code generation, update documentation, and execute relevant tests.

First pack should implement Organization, Membership, roles, invitations, current-tenant selection, actor/tenant context, and policy tests. Start with Ash attribute tenancy rather than schema-per-tenant isolation.

### Why it ranks tenth

Capability packs let starter remain lean while becoming far more versatile. Cross-cutting features no longer need permanent inclusion or copy-paste recipes. Manifest also gives agents a reliable statement of installed architecture.

Igniter tasks are composable, and Ash supports both attribute and context tenancy. Attribute tenancy is simpler and requires tenant context on each operation; see [Ash multitenancy guide](https://ash.hexdocs.pm/multitenancy.html).

### Pragmatic boundary

Keep a small curated catalog and test base plus pairwise pack combinations. Do not create a plugin marketplace, run arbitrary third-party scripts, or promise automatic removal after application code depends on a pack.

## Recommended implementation sequence

Ranking describes value, not dependency order.

1. Build generated contract foundation from idea 2.
2. Build invariant compiler from idea 7 and place it in `mix precommit`.
3. Build vertical-slice compiler from idea 1 so generated output starts typed and guarded.
4. Complete credential cockpit from idea 3.
5. Add doctor and health contract from idea 4.
6. Add asynchronous operations and API reliability from ideas 5 and 6.
7. Add durable events and data workbench from ideas 8 and 9.
8. Package organizations and later cross-cutting capabilities through idea 10.

This sequence creates leverage spine first, then user-visible trust, then durable platform capabilities. It also prevents capability-matrix complexity from arriving before code generation and invariant checks can control it.

## Shared definition of done

Each capability should include:

- Ash action and policy tests
- Controller or JSON:API tests for every exposed surface
- Playwright coverage for critical web behavior
- Structured failure output suitable for agents
- Migration and rollback review
- Web/API flavor birth verification
- Demo-removal verification where relevant
- Updated `AGENTS.md` guidance above managed usage-rules sections
- No manual edits below `usage-rules-start`
- Full `mix precommit` success in template and affected newborn matrices

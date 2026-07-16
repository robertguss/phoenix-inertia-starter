# Powerful Functionality Ideas — Phoenix Inertia Starter

**Date:** 2026-07-16  
**Scope:** Capabilities the template could ship so every newborn is more compelling, useful, and robust.  
**Audience:** End users of born apps, developers who birth projects, and AI agents that ship the next feature.

## Grounding

This repository is a **template**, not a product app. Value is what every newborn inherits:

- Ash 3 domains/resources/policies
- AshAuthentication (password, magic link, confirmation, API keys, tokens)
- Oban / AshOban
- Web: Inertia + React 19 + TypeScript
- API: AshJsonApi + OpenAPI
- Birth (`bin/new_project`), demo prune (`bin/remove_demo`), quality gate (`mix precommit`)

“Users” means both **born-app end users** and **agents/devs** who extend the kit.

Ideation process: generate a large candidate pool (~100), reject high-cost / low-ROI ideas, surface the **top 10**, plus rejects and the full pool for future passes.

### Filter rules

| Keep when… | Drop when… |
| --- | --- |
| Multiplies Notes / birth / agent loop | Needs a new distributed system |
| Leverages Ash / Oban / Inertia already in the box | Second full UI paradigm (product LiveView) |
| End-user trust **or** ship-speed step-function | Pure polish (theme-only, Storybook-only) |
| Removable or opt-in if demo-shaped | Locks template into one vertical industry |

---

## Top 10 (best of ~100)

### 1. Vertical slice compiler — `bin/add_slice`

**What:** One command: name + fields + ownership → Ash resource, policies, migration, domain interface, **and** either Inertia CRUD + tests **or** JSON:API routes + OpenAPI + tests. Same shape as Notes.

**Why brilliant:** The kit’s real product is “agent ships green feature.” Notes is the only recipe today. A compiler multiplies that forever.

**Why pragmatic:** Template copy + `ash.gen` + fixed policy/controller patterns already owned. Not a framework — a printer of known-good code.

---

### 2. Ash public surface → TypeScript contract

**What:** From public attributes/actions, emit TypeScript types + a shared **form/API error codec** (Ash `Invalid` → field errors that Inertia and JSON:API both understand). Optional Zod.

**Why brilliant:** Kills the #1 class of agent bugs: props/errors drift between Elixir and React. Dual-flavor kit becomes **one contract**, two transports.

**Why pragmatic:** Codegen over public Ash metadata + one mapper module + one TS package. No new runtime architecture.

---

### 3. Capability-scoped API keys

**What:** Keys already hash + expire. Add **scopes** (`notes:read`, `notes:write`, …) on the key; policies/plugs check actor/key metadata. Settings UI: create key, pick scopes, show secret once.

**Why brilliant:** Turns “API auth demo” into **least-privilege integration**. Matches what SaaS buyers expect; fits Ash policies cleanly.

**Why pragmatic:** Schema + policy helpers + settings page. No OAuth server. Small surface, large trust upgrade.

---

### 4. Tenant kit slice (Org + Membership + invite) — removable

**What:** Second demo slice (or `bin/add_tenancy`): Organization, Membership(role), invite-by-email (Oban/email), actor + tenant filter on resources. Exit path like `bin/remove_demo`.

**Why brilliant:** Almost every real app outgrows single-user Notes ownership. Shipping the **Ash multi-actor pattern** beats another CRUD toy.

**Why pragmatic:** Classic Ash modeling; v1 can be row-level `organization_id` + policies. Skip schema-per-tenant until needed.

---

### 5. Domain event outbox + signed webhooks

**What:** `OutboundEvent` resource: payload, destination, HMAC secret, attempts. Ash `after_transaction` enqueues; Oban worker delivers with retries + dead-letter. Partner docs: verify signature, replay.

**Why brilliant:** Makes the kit **integration-native** without microservices. Reliable “tell the outside world” turns CRUD apps into platforms.

**Why pragmatic:** Outbox + Oban is the boring correct pattern; AshOban already runs. Start with one event type from Notes as proof, then generalize.

---

### 6. `Idempotency-Key` on mutating API

**What:** Header on POST/PATCH: store key + actor + request hash + response; duplicates return same status/body. TTL cleanup via Oban.

**Why brilliant:** Tiny feature, **radical reliability** for clients, inbound webhooks, flaky networks. Differentiates from toy JSON:API starters.

**Why pragmatic:** One plug + one table + tests. No client SDK required. Web flavor can ignore it.

---

### 7. Policy Oracle (agent + admin)

**What:** Given actor + action + optional record id → `Ash.can?` result + short reason. CLI: `mix starter.can user@x update Note:id`. Optional AshAdmin panel. Fixture pattern for tests.

**Why brilliant:** Ash policies are a superpower **and** a footgun for agents. Oracle makes authorization **queryable**, not folklore. Unique for an Ash-first kit.

**Why pragmatic:** Wraps existing `Ash.can?` / authorizer; read-only tool. No new auth model.

---

### 8. Credential cockpit (sessions, keys, revoke)

**What:** Settings becomes a security hub: active sessions/tokens (`store_all_tokens? true` already), revoke one / logout-everywhere, API keys list + create + revoke, password + magic-link status. Banner when session revoked.

**Why brilliant:** Auth is strong under the hood; **user-visible control** is what feels like a real product. Completes the story without new strategies.

**Why pragmatic:** Mostly UI + token destroy actions nearly present. Highest user wow per line of code in auth.

---

### 9. Append-only audit log (first-party)

**What:** `AuditEvent` resource: actor_id, action, resource, record_id, metadata, ip/request_id. Helper change/hook on sensitive actions (auth, notes destroy, key create, admin). AshAdmin index; optional admin JSON:API read.

**Why brilliant:** Unlocks support, compliance, “who deleted this?” — and gives agents a **standard place** to attach side effects without inventing logging per feature.

**Why pragmatic:** Insert-only resource + `after_action` helper. Skip full event sourcing. Sample hooks on Notes + API keys prove the pattern.

---

### 10. Opt-in MCP tool bridge from Ash code interfaces

**What:** Config list of domain functions safe for tools → thin MCP (or “agent HTTP tools”) server: schema from action args, call with API-key actor + scopes (#3). Same policies as humans.

**Why brilliant:** 2026 differentiator: a newborn is not only web/API — it is an **agent-operable product surface** with real authz. Reuses code interfaces; no parallel business layer.

**Why pragmatic:** Start narrow (Notes CRUD + “list my notes”), one transport, refuse dangerous actions by default. Hard part is policy discipline — which the kit already teaches. Skip autonomous “NL over SQL.”

---

## Suggested build order

1. **#8 Credential cockpit** + **#3 Scoped API keys** — auth completeness; unlocks API/MCP  
2. **#2 TS contract** + **#1 Slice compiler** — agent velocity  
3. **#6 Idempotency** + **#5 Outbox webhooks** — reliability / integrations  
4. **#9 Audit log** + **#7 Policy Oracle** — operability  
5. **#4 Tenancy slice**, then **#10 MCP** — platform shape  

---

## Honorable rejects (strong, not top 10)

| Idea | Why strong | Why not top 10 |
| --- | --- | --- |
| OAuth Google / GitHub | High demand, planned in original kit notes | Valuable commodity, not innovative; needs careful Identity spike |
| Feature flags resource + Inertia share | High leverage, small | Good but less step-function than slice compiler / contracts |
| S3 / local file attachment pattern | Common product need | Commodity; good as a later slice |
| Admin impersonation + audit | Support/debug killer | Security-sensitive; pairs with #9, not ahead of cockpit/scopes |
| GDPR export + account delete pack | Trust / compliance | Narrower audience than audit + tenancy |
| Inertia + PubSub live table pattern | Cool dual-stack use of Phoenix | Nice-to-have vs reliability/auth foundation |
| `bin/doctor` (env, DB, mailer, Oban, drift) | Agent/dev ergonomics | DX-only; less “for end users” |
| Stripe / billing recipe | Business-critical for SaaS | Scope explosion; industry-locking if too deep |

### Explicitly rejected (too hard or not worth complexity)

- Multi-region data / active-active
- Offline-first sync (CRDT notes, etc.)
- Full billing platform (plans, dunning, tax, invoicing as core kit)
- GraphQL as a second public API beside JSON:API
- SCIM / LDAP enterprise directory
- Full CQRS + event store
- Natural-language query over arbitrary DB
- Product LiveView UI (contradicts Inertia product direction)

---

## Full candidate pool (~100)

Ideas generated before ranking. Grouped by axis. Top-10 and honorable rejects are marked.

### Template birth / agent DX

1. **[TOP #1]** Scaffold generator for Ash resource + Inertia CRUD + tests + JSON:API (`bin/add_slice`)
2. Feature recipe system (copy-paste slices beyond Notes)
3. Slice templates registry (billing stub, blog, comments, …)
4. CLI for agents: `bin/add_resource Note title:string body:string`
5. `bin/doctor` for env / deps / DB / migrations / mailer / Oban
6. Living `AGENTS.md` regenerated from code graph
7. Plugin architecture for optional slices
8. Multi-app monorepo birth (web + API same domain)
9. Schema evolution checklist in agent docs
10. Resource snapshot diff in CI beyond migrations
11. Dependency freshness bot / documented refresh automation
12. Seed scenarios (demo data packs)
13. Playwright auth helpers as first-class kit utilities
14. Chaos tests for auth flows
15. Property tests for policies
16. Policy tests auto-generated from policy DSL
17. Contract tests for JSON:API
18. Typed dual-surface contract tests (web + API same action path)
19. Visual regression in CI
20. Load-test harness (k6) smoke pack

### Auth & identity

21. OAuth Google / GitHub via AshAuthentication + Inertia interstitial
22. Passkeys / WebAuthn
23. 2FA TOTP
24. **[TOP #8]** Session management UI (list devices, revoke)
25. Magic-link device binding
26. Risk-based auth step-up
27. Geo-IP login alerts
28. Consent / TOS acceptance tracking
29. Cookie preference center (GDPR)
30. Admin impersonation (audit-logged) with UI banner
31. Break-glass admin with time-boxed elevation
32. Admin action confirmation (type email to confirm)
33. **[TOP #3]** API key scopes / permissions
34. Personal access tokens with scopes UI (overlap with scoped keys)
35. OAuth resource-server mode (hard)
36. SCIM provisioning (hard)
37. LDAP (rejected)

### Domain / Ash patterns

38. **[TOP #9]** Audit log resource (who did what)
39. Soft-delete + trash bin pattern
40. Optimistic locking on resources
41. **[TOP #4]** Multi-tenant org model (membership, roles)
42. Invitation flow for teams
43. Feature flags (Ash resource + plug + Inertia share)
44. Comments as nested resource pattern
45. Tags many-to-many pattern
46. Versioning / history of records
47. Undo last action
48. Bulk actions with Ash bulk APIs
49. CSV import with validation report
50. Activity feed
51. Mentions / notifications pattern (generalizable from Notes)
52. Data retention policies as Oban jobs
53. Field-level encryption for sensitive attrs
54. Encryption-at-rest helpers for selected attributes
55. Quotas per plan (needs billing context)
56. Usage metering

### Web UI (Inertia / React)

57. **[TOP #2]** Shared form error mapper TS + Elixir (Ash → field errors)
58. TypeScript types generated from Ash public attributes
59. Inertia shared props as typed Zod schemas
60. Infinite-scroll Notes pattern as demo upgrade
61. Command palette in app shell
62. Keyboard-first navigation
63. Dark mode + system preference
64. i18n (Gettext + React i18n)
65. Timezone-aware user preferences
66. Design tokens / theme switcher
67. Storybook for React components
68. Server-driven UI component catalog
69. PWA shell (installable, offline shell only)
70. Inertia partial reloads + Phoenix channels live updates
71. Presence indicators
72. Notification center (in-app + email)

### API surface

73. Typed API client generated from OpenAPI for TypeScript
74. Generated OpenAPI → typed fetch client used by web flavor (self-dogfood)
75. GraphQL via AshGraphql (rejected as second public API by default)
76. API versioning strategy + deprecation headers
77. **[TOP #6]** Idempotency keys on mutating API
78. Cursor pagination consistency everywhere
79. Client SDK package publish path
80. Embeddable widget SDK
81. **[TOP #10]** AI agent tool endpoints / MCP server from Ash resources
82. Natural-language query over own data (rejected — hard / unsafe)

### Jobs / reliability / integrations

83. **[TOP #5]** Outbound webhooks with signing + outbox
84. Inbound webhook receiver with HMAC verification
85. Inbox / outbox for reliable external calls (general)
86. Domain event outbox for integrations (general form of #5)
87. Background job status surface for end users (beyond LiveDashboard)
88. Progress polling pattern for long-running jobs
89. Dead-letter queue UI for failed Oban jobs
90. Cron / scheduled-action visibility for ops
91. Scheduled reports
92. Rate limiting (plug + cleanup)

### Ops / observability / deploy

93. Request ID correlation end-to-end (logs, errors, Inertia)
94. Health check endpoint for k8s / Fly
95. Ready / live probes
96. OpenTelemetry traces out of the box
97. Sentry / error-tracking stub
98. Feature environment matrix (preview deploys notes)
99. Read-replica repo config pattern
100. Secrets rotation runbook automation
101. Security headers audit in precommit
102. CSP nonce automation

### Collaboration / product / compliance

103. File uploads via S3 + Ash
104. Image variants / transforms
105. Full-text search with Postgres `tsvector`
106. Export data (CSV/JSON) for GDPR
107. Account deletion cascade
108. Email preference center
109. Marketing unsubscribe
110. First-party feature usage analytics
111. PostHog / Plausible analytics stub
112. Stripe billing recipe (Ash + webhooks + Oban)
113. Multi-region notes (rejected — hard)
114. Offline-capable notes with sync (rejected — hard)
115. CQRS read models (rejected — heavy)

### Authorization DX (extra)

116. **[TOP #7]** Policy visualization / debugger for agents (`can?` oracle)
117. `mix ash.can`-style UI for “what can this user do”
118. Policy simulation endpoint for agents

---

## Next steps

- Pick 1–2 top ideas for a requirements brainstorm (`ce-brainstorm` / plan under `docs/plans/`).
- Rank against product target: **SaaS multi-tenant** vs **API-first** vs **agent-first**.
- Prefer removable or opt-in demos so the template stays a kit, not a product.

## Provenance

Captured from an ideation pass (2026-07-16) over this starter kit’s actual stack and constraints. Not a commitment to implement; ranking is opinionated for leverage vs complexity.

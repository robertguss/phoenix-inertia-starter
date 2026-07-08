# StarterKitWeb Guide

## Overview

Phoenix web code is split by surface: Inertia browser pages, JSON:API, admin
LiveView islands, and dev-only tools. Keep those surfaces separated.

## Structure

```text
lib/starter_kit_web/
|-- router.ex                 # browser/API/admin/dev scopes
|-- controllers/              # Inertia and JSON error controllers
|-- controllers/auth/         # Pattern B AshAuthentication controllers
|-- plugs/                    # current-user, auth gates, API actor setup
|-- ash_admin_actor_plug.ex   # gives AshAdmin the signed-in Ash actor
|-- api_router.ex             # AshJsonApi router
|-- components/layouts.*      # Inertia root layout only
`-- endpoint.ex               # Phoenix endpoint + Vite manifest/static wiring
```

## Where To Look

| Task | Location | Notes |
| --- | --- | --- |
| Browser routes | `router.ex` | Inside `PRUNE:WEB` browser scopes. |
| API routes | `api_router.ex`, `router.ex` | AshJsonApi mounted under `/api/v1`; docs stay public only as configured. |
| Auth page flow | `controllers/auth/` | Plain controllers plus Inertia pages; no AshAuthentication LiveView routes. |
| Current user | `plugs/fetch_current_user.ex` | Session retrieval for browser/admin pipelines. |
| Inertia shared props | `plugs/inertia_share.ex` | Serializes `current_user` to global page props. |
| Admin access | `plugs/require_admin.ex`, `ash_admin_actor_plug.ex` | Dev-open, prod admin-only; AshAdmin needs actor session wiring. |

## Conventions

- Product UI routes render Inertia components with `assign_prop/3` and
  `render_inertia/2`; do not introduce HEEx product pages.
- Auth uses Pattern B: controllers call Ash code interfaces and helpers such as
  `store_in_session`, `retrieve_from_session`, and `set_actor`.
- Keep `forward "/", StarterKitWeb.ApiRouter` last inside the `/api/v1` scope.
- Admin and dashboard routes use their own pipeline because their LiveView layout
  and CSP needs differ from Inertia pages.
- Web-only routes and plugs must remain inside `PRUNE:WEB` blocks so `--api`
  newborns do not retain Inertia residue.

## Anti-Patterns

- Do not put Ash business rules in controllers or plugs.
- Do not make API auth depend on browser session state.
- Do not make AshAdmin authorization rely only on `conn.assigns.current_user`;
  the custom actor plug bridges that user into AshAdmin.
- Do not add generic Phoenix core component patterns for product UI; this app's
  product surface is React/Inertia.

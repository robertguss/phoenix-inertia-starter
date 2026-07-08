# Inertia Frontend Guide

## Overview

This is the web-flavor React 19 + Inertia + TypeScript surface. The entire
`assets/` tree is pruned for `--api` newborns.

## Structure

```text
assets/js/
|-- app.tsx              # Inertia app bootstrap and eager page resolver
|-- pages/               # route components named from controller render calls
|-- pages/auth/          # auth screens for Pattern B controllers
|-- pages/notes/         # demo Notes UI, removed by bin/remove_demo
|-- components/field.tsx # Inertia useForm-compatible field helper
|-- components/ui/       # copied shadcn/ui primitives kept as the core set
|-- components/flash.tsx # server flash renderer
`-- types/               # shared page prop and domain types
```

## Where To Look

| Task | Location | Notes |
| --- | --- | --- |
| Add a page | `pages/**` | Path must match the server's `render_inertia/2` component name. |
| Build a form | `components/field.tsx`, existing auth/notes pages | Use Inertia `useForm`; compose primitives directly. |
| Add shared props | `types/index.ts`, server `InertiaShare` plug | Keep TypeScript props aligned with serialized server shape. |
| Confirmation modal | `components/ui/dialog.tsx`, `pages/notes/index.tsx` | Existing Dialog usage proves the copied primitive works. |
| Flash messages | `components/flash.tsx` | Reads shared flash props. |

## Conventions

- Use `@/` imports; `vite.config.ts` defines the alias.
- Page modules are eagerly globbed in `app.tsx`. A missing file throws
  `Unknown Inertia page`.
- Use the local `Field` helper for Inertia forms. The shadcn `Form` primitive is
  react-hook-form oriented and is not the default form pattern here.
- Keep UI types explicit. Domain shapes live in `types/auth.ts` and `types/notes.ts`.
- Demo files under `pages/notes/` must remain removable by `bin/remove_demo`.

## Anti-Patterns

- Do not add LiveView/HEEx product UI from this directory's changes.
- Do not place permanent product code under `pages/notes/`; that slice is demo.
- Do not add frontend references outside `PRUNE:WEB`-aware surfaces without
  checking the `--api` prune.

// Typed Inertia page props (R12). `SharedProps` are injected on every page by a
// server-side plug (see U5's inertia_share); a page's own props are composed on
// top with `PageProps<T>`.

export interface SharedProps {
  // `current_user` and `flash` land here once U5 wires the shared-props plug.
  [key: string]: unknown;
}

export type PageProps<T = Record<string, never>> = T & SharedProps;

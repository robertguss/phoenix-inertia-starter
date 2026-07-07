// Typed Inertia page props (R12). `SharedProps` are injected on every page by the
// server (the `InertiaShare` plug shares `current_user`; Inertia shares `flash` and
// `errors`). A page's own props are composed on top with `PageProps<T>`.

import type { User } from "@/types/auth";

export interface Flash {
  info?: string;
  error?: string;
}

export interface SharedProps {
  current_user: User | null;
  flash: Flash;
  errors: Record<string, string>;
  // Inertia's `usePage<T>()` requires page props to carry an index signature.
  [key: string]: unknown;
}

export type PageProps<T = Record<string, never>> = T & SharedProps;

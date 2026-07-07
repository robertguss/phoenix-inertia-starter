// Auth-related shared types (R12). `User` mirrors the minimal public map the
// `InertiaShare` plug serializes — never the full Ash resource.

export interface User {
  id: string;
  email: string;
}

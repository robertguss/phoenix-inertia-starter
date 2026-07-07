import type { FormEvent } from "react";
import { useForm } from "@inertiajs/react";

import type { PageProps } from "@/types";
import { AuthShell } from "@/components/auth-shell";
import { Button } from "@/components/ui/button";

// The magic-link token is only consumed on this explicit POST, so the emailed
// GET link lands here first and email scanners/prefetchers can't sign anyone in.
export default function MagicLinkConfirm({ token }: PageProps<{ token: string }>) {
  const form = useForm({ token });

  function submit(e: FormEvent) {
    e.preventDefault();
    form.post("/auth/magic-link");
  }

  return (
    <AuthShell
      title="Sign in"
      description="Click below to finish signing in to your account."
    >
      <form onSubmit={submit}>
        <Button type="submit" className="w-full" disabled={form.processing}>
          Sign in
        </Button>
      </form>
    </AuthShell>
  );
}

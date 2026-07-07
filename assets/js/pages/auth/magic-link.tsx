import type { FormEvent } from "react";
import { Link, useForm } from "@inertiajs/react";

import { AuthShell } from "@/components/auth-shell";
import { Field } from "@/components/field";
import { Button } from "@/components/ui/button";

export default function MagicLink() {
  const form = useForm({ email: "" });

  function submit(e: FormEvent) {
    e.preventDefault();
    form.post("/magic-link");
  }

  return (
    <AuthShell
      title="Email me a sign-in link"
      description="No password needed — we'll send a one-time link."
      footer={
        <Link href="/sign-in" className="underline">
          Sign in with a password instead
        </Link>
      }
    >
      <form onSubmit={submit} className="space-y-4">
        <Field
          id="email"
          label="Email"
          type="email"
          autoComplete="email"
          required
          value={form.data.email}
          error={form.errors.email}
          onChange={(e) => form.setData("email", e.target.value)}
        />
        <Button type="submit" className="w-full" disabled={form.processing}>
          Send link
        </Button>
      </form>
    </AuthShell>
  );
}

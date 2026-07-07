import type { FormEvent } from "react";
import { Link, useForm } from "@inertiajs/react";

import { AuthShell } from "@/components/auth-shell";
import { Field } from "@/components/field";
import { Button } from "@/components/ui/button";

export default function ForgotPassword() {
  const form = useForm({ email: "" });

  function submit(e: FormEvent) {
    e.preventDefault();
    form.post("/forgot-password");
  }

  return (
    <AuthShell
      title="Reset your password"
      description="Enter your email and we'll send reset instructions."
      footer={
        <Link href="/sign-in" className="underline">
          Back to sign in
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
          Send reset link
        </Button>
      </form>
    </AuthShell>
  );
}

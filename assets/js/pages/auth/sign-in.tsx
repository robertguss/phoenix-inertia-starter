import type { FormEvent } from "react";
import { Link, useForm } from "@inertiajs/react";

import { AuthShell } from "@/components/auth-shell";
import { Field } from "@/components/field";
import { Button } from "@/components/ui/button";

export default function SignIn() {
  const form = useForm({ email: "", password: "" });

  function submit(e: FormEvent) {
    e.preventDefault();
    form.post("/sign-in");
  }

  return (
    <AuthShell
      title="Sign in"
      description="Welcome back."
      footer={
        <span>
          No account?{" "}
          <Link href="/register" className="underline">
            Create one
          </Link>
        </span>
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
        <Field
          id="password"
          label="Password"
          type="password"
          autoComplete="current-password"
          required
          value={form.data.password}
          error={form.errors.password}
          onChange={(e) => form.setData("password", e.target.value)}
        />
        <Button type="submit" className="w-full" disabled={form.processing}>
          Sign in
        </Button>
      </form>
      <div className="flex justify-between text-sm text-muted-foreground">
        <Link href="/magic-link" className="underline">
          Email me a link
        </Link>
        <Link href="/forgot-password" className="underline">
          Forgot password?
        </Link>
      </div>
    </AuthShell>
  );
}

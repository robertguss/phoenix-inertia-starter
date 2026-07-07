import type { FormEvent } from "react";
import { Link, useForm } from "@inertiajs/react";

import { AuthShell } from "@/components/auth-shell";
import { Field } from "@/components/field";
import { Button } from "@/components/ui/button";

export default function Register() {
  const form = useForm({
    email: "",
    password: "",
    password_confirmation: "",
  });

  function submit(e: FormEvent) {
    e.preventDefault();
    form.post("/register");
  }

  return (
    <AuthShell
      title="Create your account"
      description="We'll email you a link to confirm your address."
      footer={
        <span>
          Already have an account?{" "}
          <Link href="/sign-in" className="underline">
            Sign in
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
          autoComplete="new-password"
          required
          value={form.data.password}
          error={form.errors.password}
          onChange={(e) => form.setData("password", e.target.value)}
        />
        <Field
          id="password_confirmation"
          label="Confirm password"
          type="password"
          autoComplete="new-password"
          required
          value={form.data.password_confirmation}
          error={form.errors.password_confirmation}
          onChange={(e) => form.setData("password_confirmation", e.target.value)}
        />
        <Button type="submit" className="w-full" disabled={form.processing}>
          Create account
        </Button>
      </form>
    </AuthShell>
  );
}

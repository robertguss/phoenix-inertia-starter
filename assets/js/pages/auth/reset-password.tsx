import type { FormEvent } from "react";
import { useForm } from "@inertiajs/react";

import type { PageProps } from "@/types";
import { AuthShell } from "@/components/auth-shell";
import { Field } from "@/components/field";
import { Button } from "@/components/ui/button";

type ResetPasswordProps = PageProps<{ token: string }>;

export default function ResetPassword({ token }: ResetPasswordProps) {
  const form = useForm({
    token,
    password: "",
    password_confirmation: "",
  });

  function submit(e: FormEvent) {
    e.preventDefault();
    form.post("/auth/reset-password");
  }

  return (
    <AuthShell title="Choose a new password" description="Enter and confirm your new password.">
      <form onSubmit={submit} className="space-y-4">
        <Field
          id="password"
          label="New password"
          type="password"
          autoComplete="new-password"
          required
          value={form.data.password}
          error={form.errors.password}
          onChange={(e) => form.setData("password", e.target.value)}
        />
        <Field
          id="password_confirmation"
          label="Confirm new password"
          type="password"
          autoComplete="new-password"
          required
          value={form.data.password_confirmation}
          error={form.errors.password_confirmation}
          onChange={(e) => form.setData("password_confirmation", e.target.value)}
        />
        <Button type="submit" className="w-full" disabled={form.processing}>
          Reset password
        </Button>
      </form>
    </AuthShell>
  );
}

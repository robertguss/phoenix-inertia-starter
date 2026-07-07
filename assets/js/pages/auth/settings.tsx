import type { FormEvent } from "react";
import { Link, useForm, usePage } from "@inertiajs/react";

import type { SharedProps } from "@/types";
import { Field } from "@/components/field";
import { Flash } from "@/components/flash";
import { Button } from "@/components/ui/button";
import {
  Card,
  CardContent,
  CardDescription,
  CardHeader,
  CardTitle,
} from "@/components/ui/card";

export default function Settings() {
  const { current_user } = usePage<SharedProps>().props;
  const form = useForm({
    current_password: "",
    password: "",
    password_confirmation: "",
  });

  function submit(e: FormEvent) {
    e.preventDefault();
    form.put("/settings/password", { onSuccess: () => form.reset() });
  }

  return (
    <main className="mx-auto flex min-h-screen max-w-lg flex-col gap-6 p-6">
      <header className="flex items-center justify-between">
        <div>
          <h1 className="text-2xl font-bold tracking-tight">Account settings</h1>
          <p className="text-sm text-muted-foreground">{current_user?.email}</p>
        </div>
        <Link
          href="/sign-out"
          method="delete"
          as="button"
          className="text-sm text-muted-foreground underline"
        >
          Sign out
        </Link>
      </header>

      <Flash />

      <Card>
        <CardHeader>
          <CardTitle>Change password</CardTitle>
          <CardDescription>
            Enter your current password and choose a new one.
          </CardDescription>
        </CardHeader>
        <CardContent>
          <form onSubmit={submit} className="space-y-4">
            <Field
              id="current_password"
              label="Current password"
              type="password"
              autoComplete="current-password"
              required
              value={form.data.current_password}
              error={form.errors.current_password}
              onChange={(e) => form.setData("current_password", e.target.value)}
            />
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
            <Button type="submit" disabled={form.processing}>
              Update password
            </Button>
          </form>
        </CardContent>
      </Card>
    </main>
  );
}

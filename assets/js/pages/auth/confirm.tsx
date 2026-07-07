import type { FormEvent } from "react";
import { useForm } from "@inertiajs/react";

import type { PageProps } from "@/types";
import { AuthShell } from "@/components/auth-shell";
import { Button } from "@/components/ui/button";

type ConfirmProps = PageProps<{ token: string }>;

// The confirmation strategy requires interaction, so the emailed GET link only
// lands here — the actual confirmation is this explicit POST.
export default function Confirm({ token }: ConfirmProps) {
  const form = useForm({ token });

  function submit(e: FormEvent) {
    e.preventDefault();
    form.post("/auth/confirm");
  }

  return (
    <AuthShell
      title="Confirm your email"
      description="One more step — confirm your email address to activate your account."
    >
      <form onSubmit={submit}>
        <Button type="submit" className="w-full" disabled={form.processing}>
          Confirm email
        </Button>
      </form>
    </AuthShell>
  );
}

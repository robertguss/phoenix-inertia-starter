import { Link } from "@inertiajs/react";

import { AuthShell } from "@/components/auth-shell";

export default function ConfirmPending() {
  return (
    <AuthShell
      title="Check your email"
      description="We sent you a confirmation link. Click it to activate your account, then sign in."
      footer={
        <Link href="/sign-in" className="underline">
          Back to sign in
        </Link>
      }
    >
      <p className="text-sm text-muted-foreground">
        Didn't get it? Check your spam folder, or try registering again.
      </p>
    </AuthShell>
  );
}

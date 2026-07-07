import type { ComponentProps } from "react";

import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";

// Label + input + inline error, driven by Inertia's `useForm` (which owns the
// value/onChange/errors). shadcn's own Form component is react-hook-form based,
// so with Inertia we compose the primitives directly.
export function Field({
  id,
  label,
  error,
  ...props
}: ComponentProps<"input"> & { label: string; error?: string }) {
  return (
    <div className="space-y-1.5">
      <Label htmlFor={id}>{label}</Label>
      <Input id={id} name={id} aria-invalid={Boolean(error)} {...props} />
      {error ? <p className="text-sm text-destructive">{error}</p> : null}
    </div>
  );
}

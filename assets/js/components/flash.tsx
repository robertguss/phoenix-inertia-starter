import { usePage } from "@inertiajs/react";

import type { SharedProps } from "@/types";
import { cn } from "@/lib/utils";

// Renders the server flash (shared by Inertia on every page). Info messages are
// neutral; errors use the destructive palette.
export function Flash() {
  const { flash } = usePage<SharedProps>().props;
  const message = flash?.error ?? flash?.info;

  if (!message) return null;

  return (
    <div
      role="status"
      className={cn(
        "rounded-md border px-3 py-2 text-sm",
        flash.error
          ? "border-destructive/50 text-destructive"
          : "border-border text-foreground",
      )}
    >
      {message}
    </div>
  );
}

import { Button } from "@/components/ui/button";
import type { PageProps } from "@/types";

// Demonstrates the typed page-props pattern (R12): the controller's props are
// declared inline and composed with the shared props via PageProps<T>.
type HomeProps = PageProps<{ message: string }>;

export default function Home({ message }: HomeProps) {
  return (
    <main className="flex min-h-screen flex-col items-center justify-center gap-6 p-8 text-center">
      <h1 className="text-3xl font-bold tracking-tight">{message}</h1>
      <p className="max-w-prose text-muted-foreground">
        Inertia + React 19 + TypeScript, bundled by Vite and styled with Tailwind 4
        and shadcn/ui. Edit{" "}
        <code className="rounded bg-muted px-1.5 py-0.5 font-mono text-sm">
          assets/js/pages/home.tsx
        </code>{" "}
        to change this page.
      </p>
      <Button asChild>
        <a href="https://hexdocs.pm/inertia" target="_blank" rel="noreferrer">
          Read the Inertia docs
        </a>
      </Button>
    </main>
  );
}

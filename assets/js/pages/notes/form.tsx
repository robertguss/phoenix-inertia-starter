// DEMO: Notes create/edit form page — bin/remove_demo deletes this file.
import type { FormEvent } from "react";
import { Link, useForm, usePage } from "@inertiajs/react";

import { Field } from "@/components/field";
import { Flash } from "@/components/flash";
import { Button } from "@/components/ui/button";
import { Label } from "@/components/ui/label";
import { cn } from "@/lib/utils";
import type { PageProps } from "@/types";
import type { Note } from "@/types/notes";

type NoteFormProps = PageProps<{ note: Note | null }>;

export default function NoteForm() {
  const { note } = usePage<NoteFormProps>().props;
  const editing = note !== null;

  const form = useForm({
    title: note?.title ?? "",
    body: note?.body ?? "",
  });

  function submit(e: FormEvent) {
    e.preventDefault();

    if (note) {
      form.put(`/notes/${note.id}`);
    } else {
      form.post("/notes");
    }
  }

  return (
    <main className="mx-auto max-w-xl space-y-6 p-8">
      <h1 className="text-2xl font-bold tracking-tight">
        {editing ? "Edit note" : "New note"}
      </h1>

      <Flash />

      <form onSubmit={submit} className="space-y-4">
        <Field
          id="title"
          label="Title"
          required
          value={form.data.title}
          error={form.errors.title}
          onChange={(e) => form.setData("title", e.target.value)}
        />

        <div className="space-y-1.5">
          <Label htmlFor="body">Body</Label>
          <textarea
            id="body"
            name="body"
            rows={6}
            className={cn(
              "w-full rounded-md border border-input bg-transparent px-3 py-2 text-sm shadow-xs outline-none",
              "focus-visible:border-ring focus-visible:ring-[3px] focus-visible:ring-ring/50",
              "aria-invalid:border-destructive aria-invalid:ring-destructive/20",
            )}
            aria-invalid={Boolean(form.errors.body)}
            value={form.data.body}
            onChange={(e) => form.setData("body", e.target.value)}
          />
          {form.errors.body ? (
            <p className="text-sm text-destructive">{form.errors.body}</p>
          ) : null}
        </div>

        <div className="flex gap-2">
          <Button type="submit" disabled={form.processing}>
            {editing ? "Save" : "Create"}
          </Button>
          <Button asChild variant="outline">
            <Link href="/notes">Cancel</Link>
          </Button>
        </div>
      </form>
    </main>
  );
}

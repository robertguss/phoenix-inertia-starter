// DEMO: Notes index page — bin/remove_demo deletes this file.
import { Link, router, usePage } from "@inertiajs/react";

import { Flash } from "@/components/flash";
import { Button } from "@/components/ui/button";
import {
  Table,
  TableBody,
  TableCell,
  TableHead,
  TableHeader,
  TableRow,
} from "@/components/ui/table";
import type { PageProps } from "@/types";
import type { Note } from "@/types/notes";

type NotesIndexProps = PageProps<{ notes: Note[] }>;

export default function NotesIndex() {
  const { notes } = usePage<NotesIndexProps>().props;

  function destroy(id: string) {
    if (window.confirm("Delete this note?")) {
      router.delete(`/notes/${id}`);
    }
  }

  return (
    <main className="mx-auto max-w-3xl space-y-6 p-8">
      <div className="flex items-center justify-between">
        <h1 className="text-2xl font-bold tracking-tight">Notes</h1>
        <Button asChild>
          <Link href="/notes/new">New note</Link>
        </Button>
      </div>

      <Flash />

      {notes.length === 0 ? (
        <p className="text-muted-foreground">No notes yet. Create your first one.</p>
      ) : (
        <Table>
          <TableHeader>
            <TableRow>
              <TableHead>Title</TableHead>
              <TableHead className="w-0 text-right">Actions</TableHead>
            </TableRow>
          </TableHeader>
          <TableBody>
            {notes.map((note) => (
              <TableRow key={note.id}>
                <TableCell className="font-medium">{note.title}</TableCell>
                <TableCell className="flex justify-end gap-3 whitespace-nowrap">
                  <Link href={`/notes/${note.id}/edit`} className="underline">
                    Edit
                  </Link>
                  <button
                    type="button"
                    onClick={() => destroy(note.id)}
                    className="text-destructive underline"
                  >
                    Delete
                  </button>
                </TableCell>
              </TableRow>
            ))}
          </TableBody>
        </Table>
      )}
    </main>
  );
}

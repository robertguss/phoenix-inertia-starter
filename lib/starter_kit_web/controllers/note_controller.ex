# DEMO: Notes web surface — `bin/remove_demo` deletes this whole file.
defmodule StarterKitWeb.NoteController do
  @moduledoc """
  Demo Notes CRUD (R23, KTD3 Pattern B): plain controller + Inertia pages, owner
  scoping enforced by passing `current_user` as the Ash actor. Behind
  `:require_authenticated`, so `current_user` is always present. Deleted by
  `bin/remove_demo`.
  """
  use StarterKitWeb, :controller

  alias StarterKit.Notes

  def index(conn, _params) do
    notes = Notes.list_notes!(actor: current_user(conn))

    conn
    |> assign_prop(:notes, Enum.map(notes, &serialize/1))
    |> render_inertia("notes/index")
  end

  def new(conn, _params) do
    conn
    |> assign_prop(:note, nil)
    |> render_inertia("notes/form")
  end

  def create(conn, params) do
    case Notes.create_note(note_params(params), actor: current_user(conn)) do
      {:ok, _note} ->
        conn
        |> put_flash(:info, "Note created.")
        |> redirect(to: ~p"/notes")

      {:error, error} ->
        conn
        |> assign_prop(:note, nil)
        |> assign_errors(error)
        |> render_inertia("notes/form")
    end
  end

  def edit(conn, %{"id" => id}) do
    with_note(conn, id, fn note ->
      conn
      |> assign_prop(:note, serialize(note))
      |> render_inertia("notes/form")
    end)
  end

  def update(conn, %{"id" => id} = params) do
    with_note(conn, id, fn note ->
      case Notes.update_note(note, note_params(params), actor: current_user(conn)) do
        {:ok, _note} ->
          conn
          |> put_flash(:info, "Note updated.")
          |> redirect(to: ~p"/notes")

        {:error, error} ->
          conn
          |> assign_prop(:note, serialize(note))
          |> assign_errors(error)
          |> render_inertia("notes/form")
      end
    end)
  end

  def delete(conn, %{"id" => id}) do
    with_note(conn, id, fn note ->
      :ok = Notes.destroy_note(note, actor: current_user(conn))

      conn
      |> put_flash(:info, "Note deleted.")
      |> redirect(to: ~p"/notes")
    end)
  end

  defp current_user(conn), do: conn.assigns.current_user

  defp note_params(params), do: %{title: params["title"], body: params["body"]}

  # Owner scoping: `get_note` filters to the actor's notes, so someone else's id
  # (or a missing one) comes back as an error — bounce to the index rather than 500.
  defp with_note(conn, id, fun) do
    case Notes.get_note(id, actor: current_user(conn)) do
      {:ok, note} ->
        fun.(note)

      {:error, _} ->
        conn
        |> put_flash(:error, "Note not found.")
        |> redirect(to: ~p"/notes")
    end
  end

  defp serialize(note) do
    %{id: note.id, title: note.title, body: note.body}
  end
end

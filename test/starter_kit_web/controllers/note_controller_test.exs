# DEMO: Notes controller tests — bin/remove_demo deletes this file.
defmodule StarterKitWeb.NoteControllerTest do
  @moduledoc """
  Demo Notes web surface (R23): the index renders the signed-in user's notes as
  Inertia props; anonymous visitors are bounced to sign-in by `:require_authenticated`.
  """
  use StarterKitWeb.ConnCase, async: true

  import Inertia.Testing
  import StarterKit.Generators

  alias StarterKit.Notes

  describe "index" do
    test "renders the signed-in user's notes as Inertia props", %{conn: conn} do
      user = generate(confirmed_user())
      {:ok, _} = Notes.create_note(%{title: "My note"}, actor: user)

      conn = conn |> sign_in(user) |> get(~p"/notes")

      assert inertia_component(conn) == "notes/index"
      assert %{notes: [%{title: "My note"}]} = inertia_props(conn)
    end

    test "redirects an anonymous visitor to sign-in", %{conn: conn} do
      conn = get(conn, ~p"/notes")
      assert redirected_to(conn) == ~p"/sign-in"
    end
  end

  describe "create" do
    test "creates a note for the signed-in user and redirects", %{conn: conn} do
      user = generate(confirmed_user())

      conn = conn |> sign_in(user) |> post(~p"/notes", %{title: "Fresh", body: "note"})

      assert redirected_to(conn) == ~p"/notes"
      assert [%{title: "Fresh"}] = Notes.list_notes!(actor: user)
    end

    test "a blank title re-renders the form with errors", %{conn: conn} do
      user = generate(confirmed_user())

      conn = conn |> sign_in(user) |> post(~p"/notes", %{title: "", body: "no title"})

      assert inertia_component(conn) == "notes/form"
      assert inertia_errors(conn) != %{}
      assert Notes.list_notes!(actor: user) == []
    end
  end

  describe "owner CRUD" do
    test "the owner can edit, update, and delete their own note", %{conn: conn} do
      user = generate(confirmed_user())
      {:ok, note} = Notes.create_note(%{title: "Mine", body: "original"}, actor: user)

      # edit (GET) renders the form pre-filled with the note.
      edit = conn |> sign_in(user) |> get(~p"/notes/#{note.id}/edit")
      assert inertia_component(edit) == "notes/form"
      assert %{note: %{title: "Mine"}} = inertia_props(edit)

      # update (PUT) persists the change.
      updated =
        conn |> sign_in(user) |> put(~p"/notes/#{note.id}", %{title: "Edited", body: "changed"})

      assert redirected_to(updated) == ~p"/notes"
      assert {:ok, %{title: "Edited"}} = Notes.get_note(note.id, actor: user)

      # delete (DELETE) removes it.
      deleted = conn |> sign_in(user) |> delete(~p"/notes/#{note.id}")
      assert redirected_to(deleted) == ~p"/notes"
      assert {:error, _} = Notes.get_note(note.id, actor: user)
    end
  end

  describe "cross-user isolation" do
    test "a non-owner cannot edit, update, or delete another user's note", %{conn: conn} do
      alice = generate(confirmed_user())
      bob = generate(confirmed_user())
      {:ok, note} = Notes.create_note(%{title: "alice secret", body: "hush"}, actor: alice)

      # bob is bounced to the index with a not-found flash on every action, and
      # never learns the note exists.
      edit = conn |> sign_in(bob) |> get(~p"/notes/#{note.id}/edit")
      assert redirected_to(edit) == ~p"/notes"
      assert Phoenix.Flash.get(edit.assigns.flash, :error) == "Note not found."

      update =
        conn |> sign_in(bob) |> put(~p"/notes/#{note.id}", %{title: "hijacked", body: "pwned"})

      assert redirected_to(update) == ~p"/notes"
      assert Phoenix.Flash.get(update.assigns.flash, :error) == "Note not found."

      delete = conn |> sign_in(bob) |> delete(~p"/notes/#{note.id}")
      assert redirected_to(delete) == ~p"/notes"
      assert Phoenix.Flash.get(delete.assigns.flash, :error) == "Note not found."

      # alice's note is untouched: still present with its original attributes.
      assert {:ok, %{title: "alice secret", body: "hush"}} = Notes.get_note(note.id, actor: alice)
    end
  end

  defp sign_in(conn, user) do
    post(conn, ~p"/sign-in", email: to_string(user.email), password: password())
  end
end

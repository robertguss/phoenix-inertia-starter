# DEMO: Notes resource tests — bin/remove_demo deletes this file.
defmodule StarterKit.Notes.NoteTest do
  @moduledoc """
  Demo Notes resource (R23): CRUD through the real actions plus the owner policy
  (a user only ever touches their own notes) and a title-validation property.
  """
  use StarterKit.DataCase, async: true
  use ExUnitProperties

  import StarterKit.Generators

  alias StarterKit.Notes

  describe "create" do
    test "belongs to the acting user" do
      user = generate(confirmed_user())

      assert {:ok, note} = Notes.create_note(%{title: "Hello", body: "world"}, actor: user)
      assert note.user_id == user.id
      assert note.title == "Hello"
    end

    test "requires an authenticated actor" do
      # With no actor there is no owner to relate the note to, so the create is
      # rejected before it can be persisted.
      assert {:error, %Ash.Error.Invalid{}} = Notes.create_note(%{title: "x"}, actor: nil)
    end

    test "rejects a blank title" do
      user = generate(confirmed_user())
      assert {:error, %Ash.Error.Invalid{}} = Notes.create_note(%{title: ""}, actor: user)
    end

    property "accepts any 1..200 character title" do
      user = generate(confirmed_user())

      check all(title <- string(:alphanumeric, min_length: 1, max_length: 200)) do
        assert {:ok, note} = Notes.create_note(%{title: title}, actor: user)
        assert note.title == title
      end
    end
  end

  describe "owner policy" do
    test "a user only lists their own notes" do
      alice = generate(confirmed_user())
      bob = generate(confirmed_user())
      {:ok, _} = Notes.create_note(%{title: "alice note"}, actor: alice)
      {:ok, _} = Notes.create_note(%{title: "bob note"}, actor: bob)

      assert [%{title: "alice note"}] = Notes.list_notes!(actor: alice)
      assert [%{title: "bob note"}] = Notes.list_notes!(actor: bob)
    end

    test "a non-owner cannot read a specific note" do
      alice = generate(confirmed_user())
      bob = generate(confirmed_user())
      {:ok, note} = Notes.create_note(%{title: "alice"}, actor: alice)

      assert {:error, _} = Notes.get_note(note.id, actor: bob)
    end

    test "a non-owner cannot update another user's note" do
      alice = generate(confirmed_user())
      bob = generate(confirmed_user())
      {:ok, note} = Notes.create_note(%{title: "alice"}, actor: alice)

      assert {:error, %Ash.Error.Forbidden{}} =
               Notes.update_note(note, %{title: "hijacked"}, actor: bob)
    end

    test "the owner can update and destroy their note" do
      user = generate(confirmed_user())
      {:ok, note} = Notes.create_note(%{title: "draft"}, actor: user)

      assert {:ok, updated} = Notes.update_note(note, %{title: "final"}, actor: user)
      assert updated.title == "final"
      assert :ok = Notes.destroy_note(updated, actor: user)
      assert [] = Notes.list_notes!(actor: user)
    end
  end

  # F19 / KTD-R6: the admin bypass policy lets an admin actor manage every note, not
  # just their own — the same fix that makes AshAdmin list rows for an admin.
  describe "admin bypass" do
    test "an admin lists and edits notes owned by other users" do
      owner = generate(confirmed_user(admin?: false))
      admin = generate(confirmed_user(admin?: true))
      {:ok, note} = Notes.create_note(%{title: "owner note"}, actor: owner)

      assert "owner note" in Enum.map(Notes.list_notes!(actor: admin), & &1.title)
      assert {:ok, %{title: "edited"}} = Notes.update_note(note, %{title: "edited"}, actor: admin)

      # Non-regression: the admin bypass opens nothing for a non-admin — a different
      # user still sees none of the owner's notes.
      other = generate(confirmed_user(admin?: false))
      assert Notes.list_notes!(actor: other) == []
    end
  end
end

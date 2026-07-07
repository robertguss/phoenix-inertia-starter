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
  end

  defp sign_in(conn, user) do
    post(conn, ~p"/sign-in", email: to_string(user.email), password: password())
  end
end

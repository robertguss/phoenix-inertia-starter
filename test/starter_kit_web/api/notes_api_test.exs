# DEMO: Notes JSON:API tests — bin/remove_demo deletes this file.
defmodule StarterKitWeb.Api.NotesApiTest do
  @moduledoc """
  Demo Notes over JSON:API (R23, R13, R14): API-key-scoped CRUD and cross-user
  isolation — one user's key can neither list nor modify another user's notes.
  """
  use StarterKitWeb.ConnCase, async: true

  import StarterKit.Generators

  alias StarterKit.Notes

  @json_api "application/vnd.api+json"

  defp key_for(user) do
    StarterKit.Accounts.ApiKey
    |> Ash.Changeset.for_create(
      :create,
      %{user_id: user.id, expires_at: DateTime.add(DateTime.utc_now(), 3600)},
      authorize?: false
    )
    |> Ash.create!()
    |> then(& &1.__metadata__.plaintext_api_key)
  end

  defp api(conn, key) do
    conn
    |> Plug.Conn.put_req_header("accept", @json_api)
    |> Plug.Conn.put_req_header("content-type", @json_api)
    |> Plug.Conn.put_req_header("authorization", "Bearer " <> key)
  end

  defp note_payload(attributes, id \\ nil) do
    data = %{type: "note", attributes: attributes}
    data = if id, do: Map.put(data, :id, id), else: data
    Jason.encode!(%{data: data})
  end

  test "rejects note creation without credentials", %{conn: conn} do
    conn =
      conn
      |> Plug.Conn.put_req_header("accept", @json_api)
      |> Plug.Conn.put_req_header("content-type", @json_api)
      |> post("/api/v1/notes", note_payload(%{title: "x"}))

    # No actor -> no owner to relate the note to, so the write is rejected (400).
    # (The clean unauthenticated-403 path is proven against /users in json_api_test.)
    assert conn.status == 400
  end

  test "a valid key creates and lists only the caller's notes", %{conn: conn} do
    user = generate(confirmed_user())
    key = key_for(user)

    created =
      post(api(conn, key), "/api/v1/notes", note_payload(%{title: "API note", body: "hi"}))

    assert created.status == 201
    assert %{"data" => %{"attributes" => %{"title" => "API note"}}} = json_response(created, 201)

    listed = get(api(build_conn(), key), "/api/v1/notes")
    assert %{"data" => [%{"attributes" => %{"title" => "API note"}}]} = json_response(listed, 200)
  end

  test "one user's key cannot list or modify another user's notes", %{conn: conn} do
    alice = generate(confirmed_user())
    bob = generate(confirmed_user())
    {:ok, note} = Notes.create_note(%{title: "alice secret"}, actor: alice)
    bob_key = key_for(bob)

    listed = get(api(build_conn(), bob_key), "/api/v1/notes")
    assert %{"data" => []} = json_response(listed, 200)

    patched =
      patch(
        api(conn, bob_key),
        "/api/v1/notes/#{note.id}",
        note_payload(%{title: "hijacked"}, note.id)
      )

    assert patched.status in [403, 404]
  end
end

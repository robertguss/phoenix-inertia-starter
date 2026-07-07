defmodule StarterKitWeb.Api.JsonApiTest do
  @moduledoc """
  JSON:API layer + API auth (U7 / R13, R14). Proves the OpenAPI spec + docs are
  served, and that both credential types (API key, JWT bearer) authenticate through
  Ash policies — an unauthenticated or expired credential is rejected, and a valid
  one only ever sees its own record.
  """
  use StarterKitWeb.ConnCase, async: true

  import StarterKit.Generators

  @json_api "application/vnd.api+json"

  defp future, do: DateTime.add(DateTime.utc_now(), 3600, :second)
  defp past, do: DateTime.add(DateTime.utc_now(), -3600, :second)

  # Creates a key and returns its plaintext (available once, right after creation).
  defp api_key_plaintext(user, expires_at) do
    StarterKit.Accounts.ApiKey
    |> Ash.Changeset.for_create(:create, %{user_id: user.id, expires_at: expires_at},
      authorize?: false
    )
    |> Ash.create!()
    |> Map.fetch!(:__metadata__)
    |> Map.fetch!(:plaintext_api_key)
  end

  defp api_get(conn, path, token \\ nil) do
    conn = put_req_header(conn, "accept", @json_api)
    conn = if token, do: put_req_header(conn, "authorization", "Bearer " <> token), else: conn
    get(conn, path)
  end

  describe "OpenAPI + docs" do
    test "serves an OpenAPI 3.x spec listing the /users route", %{conn: conn} do
      conn = api_get(conn, "/api/v1/open_api")

      # AshJsonApi serves the spec body without a content-type header, so decode it
      # directly rather than via json_response/2.
      assert conn.status == 200
      assert %{"openapi" => version, "paths" => paths} = Jason.decode!(conn.resp_body)
      assert version =~ ~r/^3\./
      assert Map.has_key?(paths, "/api/v1/users")
    end

    test "serves the Swagger UI docs page", %{conn: conn} do
      conn = get(conn, "/api/v1/docs")
      assert html_response(conn, 200) =~ ~r/swagger/i
    end
  end

  describe "authentication and actor scoping" do
    test "rejects a request with no credentials", %{conn: conn} do
      conn = api_get(conn, "/api/v1/users")
      assert conn.status == 403
    end

    test "a valid API key authenticates and returns only the caller's record", %{conn: conn} do
      user = generate(confirmed_user())
      _other = generate(confirmed_user())
      key = api_key_plaintext(user, future())

      conn = api_get(conn, "/api/v1/users", key)

      assert %{"data" => [record]} = json_response(conn, 200)
      assert record["id"] == user.id
      assert record["attributes"]["email"] == to_string(user.email)
    end

    test "a valid JWT bearer token authenticates", %{conn: conn} do
      registered = generate(user())
      jwt = registered.__metadata__.token
      assert is_binary(jwt)

      conn = api_get(conn, "/api/v1/users", jwt)

      assert %{"data" => [record]} = json_response(conn, 200)
      assert record["id"] == registered.id
    end

    test "rejects an expired API key", %{conn: conn} do
      user = generate(confirmed_user())
      key = api_key_plaintext(user, past())

      conn = api_get(conn, "/api/v1/users", key)
      assert conn.status == 403
    end
  end
end

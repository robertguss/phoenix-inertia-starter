defmodule StarterKitWeb.AdminAccessTest do
  @moduledoc """
  AE4: the admin surfaces (AshAdmin, LiveDashboard) are open in dev but admin-only
  in production. In the :test environment `dev_routes` is unset, so the gate behaves
  exactly as it does in prod — anonymous and non-admin users are turned away, admins
  get through.

  Flavor-agnostic (F12): the `/admin` + `/dashboard` scope, the `:admin_browser`
  pipeline, and `FetchCurrentUser` all stay in both flavors, so this test lives in
  both. It signs in by storing the user straight into the session (no web sign-in
  route, which `--api` prunes) and asserts on status codes rather than the `/sign-in`
  redirect — for `--api` the anonymous path is a bare 404, not that redirect.
  """
  use StarterKitWeb.ConnCase, async: true

  import StarterKit.Generators

  alias AshAuthentication.Plug.Helpers
  alias StarterKit.Accounts
  alias StarterKit.Accounts.User

  describe "AshAdmin at /admin" do
    test "denies anonymous users", %{conn: conn} do
      conn = get(conn, "/admin")
      # --web redirects to sign-in (302); --api has no sign-in route and 404s.
      assert conn.status in [302, 404]
    end

    test "returns 404 for a signed-in non-admin", %{conn: conn} do
      user = generate(confirmed_user(admin?: false))
      conn = conn |> sign_in(user) |> get("/admin")
      assert conn.status == 404
    end

    test "lets an admin through", %{conn: conn} do
      admin = generate(confirmed_user(admin?: true))
      conn = conn |> sign_in(admin) |> get("/admin")
      assert_reachable(conn)
    end
  end

  describe "LiveDashboard at /dashboard" do
    test "denies anonymous users", %{conn: conn} do
      conn = get(conn, "/dashboard")
      assert conn.status in [302, 404]
    end

    test "lets an admin through", %{conn: conn} do
      admin = generate(confirmed_user(admin?: true))
      conn = conn |> sign_in(admin) |> get("/dashboard")
      assert_reachable(conn)
    end
  end

  # F19 / KTD-R6: the admin bypass policy proven at the Ash layer, independent of the
  # AshAdmin LiveView. This is the robust core of the fix — an admin actor passes all
  # policies (sees every row), while a non-admin stays scoped to themselves.
  describe "admin bypass policy" do
    test "an admin reads every user; a non-admin reads only themselves" do
      admin = generate(confirmed_user(admin?: true))
      non_admin = generate(confirmed_user(admin?: false))

      admin_ids = User |> Ash.read!(actor: admin, authorize?: true) |> Enum.map(& &1.id)
      assert admin.id in admin_ids
      assert non_admin.id in admin_ids

      non_admin_ids = User |> Ash.read!(actor: non_admin, authorize?: true) |> Enum.map(& &1.id)
      assert non_admin_ids == [non_admin.id]
    end
  end

  # Flavor-agnostic sign-in: run the real `sign_in_with_password` Ash action (a
  # domain action, present in both flavors) to mint a session token, then store it
  # the way the browser pipeline's FetchCurrentUser (`retrieve_from_session`) reads
  # it back. Uses no web sign-in route, so it compiles and runs under both flavors.
  # U8 reuses this to sign in an admin before asserting it can list User/Note rows.
  defp sign_in(conn, user) do
    {:ok, user} =
      Accounts.sign_in_with_password(user.email, password(), authorize?: false)

    conn
    |> Plug.Test.init_test_session(%{})
    |> Helpers.store_in_session(user)
  end

  # Passed the :require_admin gate. The surface itself may dead-render (200) or
  # redirect internally (e.g. LiveDashboard -> /dashboard/home) — either way it must
  # not be the hidden 404, and any redirect must not point back at sign-in.
  defp assert_reachable(conn) do
    assert conn.status in [200, 302]
    refute get_resp_header(conn, "location") == ["/sign-in"]
  end
end

defmodule StarterKitWeb.AdminAccessTest do
  @moduledoc """
  AE4: the admin surfaces (AshAdmin, LiveDashboard) are open in dev but admin-only
  in production. In the :test environment `dev_routes` is unset, so the gate behaves
  exactly as it does in prod — anonymous and non-admin users are turned away, admins
  get through.
  """
  use StarterKitWeb.ConnCase, async: true

  import StarterKit.Generators

  describe "AshAdmin at /admin" do
    test "redirects anonymous users to sign-in", %{conn: conn} do
      conn = get(conn, "/admin")
      assert redirected_to(conn) == ~p"/sign-in"
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
    test "redirects anonymous users to sign-in", %{conn: conn} do
      conn = get(conn, "/dashboard")
      assert redirected_to(conn) == ~p"/sign-in"
    end

    test "lets an admin through", %{conn: conn} do
      admin = generate(confirmed_user(admin?: true))
      conn = conn |> sign_in(admin) |> get("/dashboard")
      assert_reachable(conn)
    end
  end

  defp sign_in(conn, user) do
    post(conn, ~p"/sign-in", email: to_string(user.email), password: password())
  end

  # Passed the :require_admin gate. The surface itself may dead-render (200) or
  # redirect internally (e.g. LiveDashboard -> /dashboard/home) — either way it must
  # not be the sign-in redirect or the hidden 404.
  defp assert_reachable(conn) do
    assert conn.status in [200, 302]
    refute get_resp_header(conn, "location") == [~p"/sign-in"]
  end
end

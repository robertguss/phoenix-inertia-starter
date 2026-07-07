defmodule StarterKitWeb.Auth.MagicLinkControllerTest do
  use StarterKitWeb.ConnCase, async: true

  import Inertia.Testing
  import Swoosh.TestAssertions

  describe "GET /magic-link" do
    test "renders the request page", %{conn: conn} do
      conn = get(conn, ~p"/magic-link")
      assert inertia_component(conn) == "auth/magic-link"
    end
  end

  describe "POST /magic-link" do
    test "always reports success and emails a link (enumeration-safe)", %{conn: conn} do
      conn = post(conn, ~p"/magic-link", email: "someone@example.com")
      assert redirected_to(conn) == ~p"/sign-in"
      assert_email_sent()
    end
  end

  describe "GET /auth/magic-link (interstitial)" do
    test "renders the confirm page WITHOUT consuming the token", %{conn: conn} do
      email = "magic@example.com"
      post(conn, ~p"/magic-link", email: email)
      token = magic_link_token()

      # GET twice — neither consumes the token (prefetch/scanner-safe).
      c1 = get(build_conn(), ~p"/auth/magic-link?token=#{token}")
      assert inertia_component(c1) == "auth/magic-link-confirm"
      assert inertia_props(c1)[:token] == token

      c2 = get(build_conn(), ~p"/auth/magic-link?token=#{token}")
      assert inertia_component(c2) == "auth/magic-link-confirm"

      # The token is still valid — an explicit POST now signs in.
      c3 = post(build_conn(), ~p"/auth/magic-link", token: token)
      assert redirected_to(c3) == ~p"/"
    end
  end

  describe "POST /auth/magic-link (confirm)" do
    test "a valid token signs the user in (new record) and is single-use", %{conn: conn} do
      email = "magic@example.com"
      post(conn, ~p"/magic-link", email: email)
      token = magic_link_token()

      conn = post(build_conn(), ~p"/auth/magic-link", token: token)
      assert redirected_to(conn) == ~p"/"

      # The session persists — a protected page is reachable.
      conn = get(conn, ~p"/settings")
      assert inertia_component(conn) == "auth/settings"

      # Single-use: replaying the same token POST fails.
      replay = post(build_conn(), ~p"/auth/magic-link", token: token)
      assert redirected_to(replay) == ~p"/sign-in"
      assert Phoenix.Flash.get(replay.assigns.flash, :error) =~ "invalid"
    end

    test "a garbage token POST safe-fails back to sign-in with a flash", %{conn: conn} do
      conn = post(conn, ~p"/auth/magic-link", token: "not-a-real-token")
      assert redirected_to(conn) == ~p"/sign-in"
      assert Phoenix.Flash.get(conn.assigns.flash, :error) =~ "invalid"
    end
  end

  defp magic_link_token do
    assert_receive {:email, email}
    [_full, query] = Regex.run(~r{/auth/magic-link\?([^"\s]+)}, email.html_body)
    URI.decode_query(query) |> Map.fetch!("token")
  end
end

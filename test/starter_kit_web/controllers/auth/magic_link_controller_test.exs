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

  describe "GET /auth/magic-link (callback)" do
    test "a valid token signs the user in", %{conn: conn} do
      email = "magic@example.com"
      post(conn, ~p"/magic-link", email: email)
      token = magic_link_token()

      conn = get(build_conn(), ~p"/auth/magic-link?token=#{token}")
      assert redirected_to(conn) == ~p"/"

      # The session persists — a protected page is reachable.
      conn = get(conn, ~p"/settings")
      assert inertia_component(conn) == "auth/settings"
    end

    test "an invalid token safe-fails back to sign-in with a flash", %{conn: conn} do
      conn = get(conn, ~p"/auth/magic-link?token=not-a-real-token")
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

defmodule StarterKitWeb.Auth.SettingsControllerTest do
  use StarterKitWeb.ConnCase, async: true

  import StarterKit.Generators
  import Inertia.Testing

  describe "require_authenticated" do
    test "anonymous users are redirected to sign-in", %{conn: conn} do
      conn = get(conn, ~p"/settings")
      assert redirected_to(conn) == ~p"/sign-in"
    end
  end

  describe "PUT /settings/password" do
    setup %{conn: conn} do
      user = generate(confirmed_user())
      conn = post(conn, ~p"/sign-in", email: to_string(user.email), password: password())
      %{conn: conn, user: user}
    end

    test "changes the password and revokes EVERY existing session (F4)", %{conn: conn, user: user} do
      # A second, independent session for the same user, minted BEFORE the change.
      # This is what proves server-side revocation — testing only the changing conn
      # would pass even if global logout were broken (clear_session drops its cookie).
      other = post(build_conn(), ~p"/sign-in", email: to_string(user.email), password: password())
      assert get(other, ~p"/settings").status == 200

      conn =
        put(conn, ~p"/settings/password",
          current_password: password(),
          password: "brand-new-password",
          password_confirmation: "brand-new-password"
        )

      assert redirected_to(conn) == ~p"/sign-in"
      assert Phoenix.Flash.get(conn.assigns.flash, :info) =~ "sign in again"

      # log_out_everywhere flipped every stored token for this user to
      # purpose=revocation, so the OTHER session — never touched by clear_session — is
      # now dead too. A session copied to another device before the change can no
      # longer reach an auth-required page.
      assert redirected_to(get(other, ~p"/settings")) == ~p"/sign-in"
    end

    test "fails when the current password is wrong", %{conn: conn} do
      conn =
        put(conn, ~p"/settings/password",
          current_password: "wrong-current-password",
          password: "brand-new-password",
          password_confirmation: "brand-new-password"
        )

      assert inertia_component(conn) == "auth/settings"
      assert inertia_errors(conn) != %{}
    end
  end
end

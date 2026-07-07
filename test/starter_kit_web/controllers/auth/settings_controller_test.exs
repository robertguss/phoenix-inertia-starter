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

    test "changes the password, ends THIS session, and redirects to sign-in (F4)", %{conn: conn} do
      conn =
        put(conn, ~p"/settings/password",
          current_password: password(),
          password: "brand-new-password",
          password_confirmation: "brand-new-password"
        )

      assert redirected_to(conn) == ~p"/sign-in"
      assert Phoenix.Flash.get(conn.assigns.flash, :info) =~ "sign in again"

      # The controller `clear_session()`s, so THIS browser's session is dropped and
      # the next request is unauthenticated — the honest F4 guarantee (an explicit
      # sign-out of the current session, not silent breakage). NOTE: this asserts only
      # the current session; cross-device "log out everywhere" is a separate add-on
      # and is NOT proven here (see the known-issue note in the branch summary).
      assert redirected_to(get(conn, ~p"/settings")) == ~p"/sign-in"
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

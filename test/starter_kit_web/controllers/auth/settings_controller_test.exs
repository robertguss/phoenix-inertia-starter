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

    test "changes the password with the correct current password", %{conn: conn} do
      conn =
        put(conn, ~p"/settings/password",
          current_password: password(),
          password: "brand-new-password",
          password_confirmation: "brand-new-password"
        )

      assert redirected_to(conn) == ~p"/settings"
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

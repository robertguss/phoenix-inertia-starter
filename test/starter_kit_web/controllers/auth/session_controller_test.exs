defmodule StarterKitWeb.Auth.SessionControllerTest do
  use StarterKitWeb.ConnCase, async: true

  import StarterKit.Generators
  import Inertia.Testing

  describe "GET /sign-in" do
    test "renders the sign-in page", %{conn: conn} do
      conn = get(conn, ~p"/sign-in")
      assert inertia_component(conn) == "auth/sign-in"
    end
  end

  describe "POST /sign-in" do
    setup do
      %{user: generate(confirmed_user())}
    end

    test "valid credentials sign in and the session persists", %{conn: conn, user: user} do
      conn = post(conn, ~p"/sign-in", email: to_string(user.email), password: password())
      assert redirected_to(conn) == ~p"/"

      # The session survived the redirect: a protected page is now reachable.
      conn = get(conn, ~p"/settings")
      assert inertia_component(conn) == "auth/settings"
    end

    test "invalid credentials re-render the page with an error", %{conn: conn, user: user} do
      conn = post(conn, ~p"/sign-in", email: to_string(user.email), password: "wrong-password")
      assert inertia_component(conn) == "auth/sign-in"
      assert %{"email" => _message} = inertia_errors(conn)
    end

    test "an unconfirmed user cannot sign in with a password", %{conn: conn} do
      user = generate(user())
      conn = post(conn, ~p"/sign-in", email: to_string(user.email), password: password())
      assert inertia_component(conn) == "auth/sign-in"
      assert %{"email" => _message} = inertia_errors(conn)
    end
  end

  describe "DELETE /sign-out" do
    test "clears the session", %{conn: conn} do
      user = generate(confirmed_user())

      conn = post(conn, ~p"/sign-in", email: to_string(user.email), password: password())
      conn = delete(conn, ~p"/sign-out")
      assert redirected_to(conn) == ~p"/sign-in"

      # Protected pages redirect back to sign-in once the session is gone.
      conn = get(conn, ~p"/settings")
      assert redirected_to(conn) == ~p"/sign-in"
    end
  end
end

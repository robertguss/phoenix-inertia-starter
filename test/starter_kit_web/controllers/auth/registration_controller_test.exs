defmodule StarterKitWeb.Auth.RegistrationControllerTest do
  use StarterKitWeb.ConnCase, async: true

  import StarterKit.Generators
  import Inertia.Testing
  import Swoosh.TestAssertions

  describe "GET /register" do
    test "renders the registration page", %{conn: conn} do
      conn = get(conn, ~p"/register")
      assert inertia_component(conn) == "auth/register"
    end
  end

  describe "POST /register" do
    test "registers a user, emails a confirmation link, and shows confirm-pending", %{conn: conn} do
      email = "newcomer@example.com"

      conn =
        post(conn, ~p"/register",
          email: email,
          password: password(),
          password_confirmation: password()
        )

      assert redirected_to(conn) == ~p"/register/confirm-pending"
      assert_email_sent(fn sent -> sent.to == [{"", email}] end)

      # Unconfirmed: password sign-in is refused until the link is followed.
      signin = post(build_conn(), ~p"/sign-in", email: email, password: password())
      assert inertia_component(signin) == "auth/sign-in"
      assert %{"email" => _} = inertia_errors(signin)
    end

    test "an already-registered email is enumeration-safe: confirm-pending, no error, no email",
         %{conn: conn} do
      user = generate(confirmed_user())

      conn =
        post(conn, ~p"/register",
          email: to_string(user.email),
          password: password(),
          password_confirmation: password()
        )

      # Same outcome as a fresh signup — the "has already been taken" error never
      # reaches the form, and the existing account is untouched (no email). (F25)
      assert redirected_to(conn) == ~p"/register/confirm-pending"
      refute_email_sent()
    end

    test "mismatched password confirmation re-renders with errors", %{conn: conn} do
      conn =
        post(conn, ~p"/register",
          email: "mismatch@example.com",
          password: password(),
          password_confirmation: "does-not-match"
        )

      assert inertia_component(conn) == "auth/register"
      assert inertia_errors(conn) != %{}
    end
  end

  describe "confirmation" do
    test "confirming the emailed link enables password sign-in", %{conn: conn} do
      email = "confirm-me@example.com"

      post(conn, ~p"/register",
        email: email,
        password: password(),
        password_confirmation: password()
      )

      token = confirmation_token()

      confirmed = post(build_conn(), ~p"/auth/confirm", token: token)
      assert redirected_to(confirmed) == ~p"/sign-in"

      # Now the same credentials sign in successfully.
      signin = post(build_conn(), ~p"/sign-in", email: email, password: password())
      assert redirected_to(signin) == ~p"/"
    end
  end

  # Pulls the confirmation token out of the (synchronously delivered) email.
  defp confirmation_token do
    assert_receive {:email, email}
    [_full, query] = Regex.run(~r{/auth/confirm\?([^"\s]+)}, email.html_body)
    URI.decode_query(query) |> Map.fetch!("token")
  end
end

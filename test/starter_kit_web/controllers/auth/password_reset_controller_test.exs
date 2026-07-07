defmodule StarterKitWeb.Auth.PasswordResetControllerTest do
  use StarterKitWeb.ConnCase, async: true

  import StarterKit.Generators
  import Inertia.Testing
  import Swoosh.TestAssertions

  describe "GET /forgot-password" do
    test "renders the request page", %{conn: conn} do
      conn = get(conn, ~p"/forgot-password")
      assert inertia_component(conn) == "auth/forgot-password"
    end
  end

  describe "POST /forgot-password" do
    test "is enumeration-safe: known and unknown emails get the same generic response", %{
      conn: conn
    } do
      user = generate(confirmed_user())

      known = post(conn, ~p"/forgot-password", email: to_string(user.email))
      assert redirected_to(known) == ~p"/sign-in"
      known_flash = Phoenix.Flash.get(known.assigns.flash, :info)

      unknown = post(build_conn(), ~p"/forgot-password", email: "nobody@example.com")
      assert redirected_to(unknown) == ~p"/sign-in"

      # Identical flash for both — the response never leaks whether the account exists.
      assert Phoenix.Flash.get(unknown.assigns.flash, :info) == known_flash

      # Only the real account is emailed; the unknown address gets nothing.
      assert_email_sent(fn sent -> sent.to == [{"", to_string(user.email)}] end)
    end
  end

  describe "GET /auth/reset-password" do
    test "renders the reset form carrying the token prop", %{conn: conn} do
      conn = get(conn, ~p"/auth/reset-password?token=a-reset-token")
      assert inertia_component(conn) == "auth/reset-password"
      assert inertia_props(conn)[:token] == "a-reset-token"
    end
  end

  describe "POST /auth/reset-password" do
    test "a valid token resets the password: the new one signs in, the old one does not", %{
      conn: conn
    } do
      user = generate(confirmed_user())
      post(conn, ~p"/forgot-password", email: to_string(user.email))
      token = reset_token()

      new_password = "brand-new-pw-5678"

      reset =
        post(build_conn(), ~p"/auth/reset-password",
          token: token,
          password: new_password,
          password_confirmation: new_password
        )

      assert redirected_to(reset) == ~p"/sign-in"

      # The new password now signs in.
      signin =
        post(build_conn(), ~p"/sign-in", email: to_string(user.email), password: new_password)

      assert redirected_to(signin) == ~p"/"

      # The old password no longer works.
      old =
        post(build_conn(), ~p"/sign-in", email: to_string(user.email), password: password())

      assert inertia_component(old) == "auth/sign-in"
      assert %{"email" => _} = inertia_errors(old)
    end

    test "an invalid or expired token bounces to sign-in with an error flash", %{conn: conn} do
      user = generate(confirmed_user())

      reset =
        post(conn, ~p"/auth/reset-password",
          token: "not-a-real-token",
          password: "brand-new-pw-5678",
          password_confirmation: "brand-new-pw-5678"
        )

      # Bad token is not a form-field error — safe-fail to sign-in with a flash.
      assert redirected_to(reset) == ~p"/sign-in"
      assert Phoenix.Flash.get(reset.assigns.flash, :error) =~ "invalid"

      # The original password still signs in — nothing was changed.
      signin =
        post(build_conn(), ~p"/sign-in", email: to_string(user.email), password: password())

      assert redirected_to(signin) == ~p"/"
    end

    test "a valid token but mismatched passwords re-renders the form with field errors", %{
      conn: conn
    } do
      user = generate(confirmed_user())
      post(conn, ~p"/forgot-password", email: to_string(user.email))
      token = reset_token()

      reset =
        post(build_conn(), ~p"/auth/reset-password",
          token: token,
          password: "brand-new-pw-5678",
          password_confirmation: "does-not-match"
        )

      # A real token with a validation problem stays on the form (token re-assigned).
      assert inertia_component(reset) == "auth/reset-password"
      assert inertia_errors(reset) != %{}
      assert inertia_props(reset)[:token] == token
    end
  end

  # Pulls the reset token out of the (synchronously delivered) email.
  defp reset_token do
    assert_receive {:email, email}
    [_full, query] = Regex.run(~r{/auth/reset-password\?([^"\s]+)}, email.html_body)
    URI.decode_query(query) |> Map.fetch!("token")
  end
end

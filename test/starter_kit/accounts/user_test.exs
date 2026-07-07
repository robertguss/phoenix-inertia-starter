defmodule StarterKit.Accounts.UserTest do
  # async: false — these tests use Mimic (per-process mocks) and the Swoosh test
  # mailbox, both of which are simplest to reason about without concurrency.
  use StarterKit.DataCase, async: false
  use ExUnitProperties
  use Mimic

  import StarterKit.Generators

  alias StarterKit.Accounts

  @password StarterKit.Generators.password()

  # Pulls the magic-link / confirmation token back out of a sent email body. The
  # sender URL-encodes it into `?token=...`, so decode it before use.
  defp token_from_email(%Swoosh.Email{html_body: html}) do
    [encoded] = Regex.run(~r/token=([^"&\s<]+)/, html, capture: :all_but_first)
    URI.decode_www_form(encoded)
  end

  describe "registration" do
    test "with a valid email and password succeeds and sends a confirmation email" do
      email = "newuser@example.com"

      assert {:ok, user} =
               Accounts.register_with_password(email, @password, @password, authorize?: false)

      assert to_string(user.email) == email
      # Registration does not confirm the address; a confirmation email is sent.
      assert is_nil(user.confirmed_at)
      assert_receive {:email, sent}
      assert sent.subject =~ "Confirm"
      assert sent.to == [{"", email}]
    end

    test "rejects a duplicate email" do
      email = "dupe@example.com"
      {:ok, _} = Accounts.register_with_password(email, @password, @password, authorize?: false)

      assert {:error, %Ash.Error.Invalid{}} =
               Accounts.register_with_password(email, @password, @password, authorize?: false)
    end

    property "rejects malformed emails" do
      # `string(:alphanumeric, ...)` never contains `@` or `.`, so every value
      # fails the email format validation regardless of the generated input.
      check all(local <- string(:alphanumeric, min_length: 1), max_runs: 20) do
        assert {:error, %Ash.Error.Invalid{}} =
                 Accounts.register_with_password(local, @password, @password, authorize?: false)
      end
    end
  end

  describe "password sign-in" do
    test "an unconfirmed account cannot sign in with a password" do
      {:ok, user} =
        Accounts.register_with_password("unconfirmed@example.com", @password, @password,
          authorize?: false
        )

      assert is_nil(user.confirmed_at)

      assert {:error, %Ash.Error.Forbidden{errors: [failure]}} =
               Accounts.sign_in_with_password(user.email, @password, authorize?: false)

      assert %AshAuthentication.Errors.AuthenticationFailed{
               caused_by: %AshAuthentication.Errors.UnconfirmedUser{}
             } = failure
    end

    test "a confirmed account can sign in with the correct password" do
      user = generate(confirmed_user())

      assert {:ok, signed_in} =
               Accounts.sign_in_with_password(user.email, @password, authorize?: false)

      assert signed_in.id == user.id
      # A JWT is attached as action metadata for the caller to store in the session.
      assert is_binary(signed_in.__metadata__.token)
    end

    test "a wrong password fails" do
      user = generate(confirmed_user())

      assert {:error,
              %Ash.Error.Forbidden{errors: [%AshAuthentication.Errors.AuthenticationFailed{}]}} =
               Accounts.sign_in_with_password(user.email, "wrong-password", authorize?: false)
    end
  end

  describe "magic link" do
    test "a request sends an email whose token signs the user in" do
      user = generate(confirmed_user())

      assert :ok = Accounts.request_magic_link(user.email, authorize?: false)
      assert_receive {:email, sent}
      assert sent.to == [{"", to_string(user.email)}]

      token = token_from_email(sent)

      assert {:ok, signed_in} = Accounts.sign_in_with_magic_link(token, authorize?: false)
      assert signed_in.id == user.id
    end

    test "a garbage token fails to sign in" do
      assert {:error, _} =
               Accounts.sign_in_with_magic_link("not-a-real-token", authorize?: false)
    end

    test "a mail delivery failure surfaces an error and leaks no token" do
      user = generate(confirmed_user())

      stub(StarterKit.Mailer, :deliver!, fn _email -> raise "mail transport down" end)

      # Ash wraps the sender's raise; the failure surfaces rather than silently
      # succeeding, so no confirmation of "email sent" can be inferred by an attacker.
      error =
        assert_raise Ash.Error.Unknown, fn ->
          Accounts.request_magic_link!(user.email, authorize?: false)
        end

      assert Exception.message(error) =~ "mail transport down"
      # Delivery blew up, so no email (and therefore no usable token) went out.
      refute_received {:email, _}
    end
  end
end

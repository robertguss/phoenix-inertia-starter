defmodule StarterKit.Accounts do
  @moduledoc """
  Accounts domain: users, authentication tokens, and the auth code interfaces
  that controllers and tests call.
  """
  use Ash.Domain,
    otp_app: :starter_kit

  resources do
    resource StarterKit.Accounts.Token

    # Code interfaces (KTD3): controllers and tests call these instead of building
    # changesets by hand. Auth actions run under AshAuthentication's interaction
    # context, so callers pass `authorize?: false` only where they deliberately
    # bypass policies (e.g. test setup).
    resource StarterKit.Accounts.User do
      define(:register_with_password, args: [:email, :password, :password_confirmation])
      define(:sign_in_with_password, args: [:email, :password], get?: true)
      define(:request_magic_link, args: [:email])
      define(:sign_in_with_magic_link, args: [:token])
      define(:get_user_by_email, action: :get_by_email, args: [:email])

      # Account settings + password reset (U5). `change_password` is an update, so
      # its first argument is the user record; the reset request is enumeration-safe
      # (it never reveals whether the email exists).
      define(:change_password, args: [:current_password, :password, :password_confirmation])
      define(:request_password_reset, action: :request_password_reset_token, args: [:email])
    end
  end
end

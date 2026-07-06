defmodule StarterKit.Secrets do
  @moduledoc """
  Supplies secrets to AshAuthentication (the token signing key), read from
  application config so it can come from an env var in production.
  """
  use AshAuthentication.Secret

  def secret_for(
        [:authentication, :tokens, :signing_secret],
        StarterKit.Accounts.User,
        _opts,
        _context
      ) do
    Application.fetch_env(:starter_kit, :token_signing_secret)
  end
end

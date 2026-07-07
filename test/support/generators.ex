defmodule StarterKit.Generators do
  @moduledoc """
  Ash.Generator-based test fixtures (R17). Prefer these over hand-built
  changesets so fixtures stay in sync with the resource's real actions.
  """
  use Ash.Generator

  @password "password1234"

  @doc "The password all generated users are created with."
  def password, do: @password

  @doc """
  Registers a user through the real `:register_with_password` action. The
  returned user is **unconfirmed** — registration sends a confirmation email and
  leaves `confirmed_at` nil until the link is followed.
  """
  def user(opts \\ []) do
    changeset_generator(
      StarterKit.Accounts.User,
      :register_with_password,
      defaults: [
        email: sequence(:email, &"user#{&1}@example.com"),
        password: @password,
        password_confirmation: @password
      ],
      overrides: opts,
      authorize?: false
    )
  end

  @doc """
  Seeds a **confirmed** user directly (bypassing actions), with a known
  bcrypt-hashed password — the convenient starting point for sign-in tests.
  """
  def confirmed_user(opts \\ []) do
    seed_generator(
      %StarterKit.Accounts.User{
        email: sequence(:email, &"confirmed#{&1}@example.com"),
        hashed_password: Bcrypt.hash_pwd_salt(@password),
        confirmed_at: DateTime.utc_now()
      },
      overrides: opts
    )
  end
end

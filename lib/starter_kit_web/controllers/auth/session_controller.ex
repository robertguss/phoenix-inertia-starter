defmodule StarterKitWeb.Auth.SessionController do
  @moduledoc """
  Email/password sign-in and sign-out (KTD3, Pattern B). Delegates the credential
  check to the `sign_in_with_password` Ash action and uses
  `AshAuthentication.Plug.Helpers` for the session plumbing.
  """
  use StarterKitWeb, :controller

  alias AshAuthentication.Plug.Helpers
  alias StarterKit.Accounts

  def new(conn, _params) do
    render_inertia(conn, "auth/sign-in")
  end

  def create(conn, %{"email" => email, "password" => password}) do
    # Auth actions run `authorize?: false` (Pattern B convention): they are the
    # authentication boundary and secure themselves (here, the password check).
    case Accounts.sign_in_with_password(email, password, authorize?: false) do
      {:ok, user} ->
        conn
        |> Helpers.store_in_session(user)
        |> put_flash(:info, "Welcome back!")
        |> redirect(to: ~p"/")

      {:error, _reason} ->
        # AshAuthentication returns an opaque failure to avoid leaking whether the
        # email exists — surface a single generic message on the email field.
        conn
        |> assign_errors(%{"email" => "Invalid email or password."})
        |> render_inertia("auth/sign-in")
    end
  end

  def delete(conn, _params) do
    conn
    |> Helpers.revoke_session_tokens(:starter_kit)
    |> clear_session()
    |> put_flash(:info, "You have been signed out.")
    |> redirect(to: ~p"/sign-in")
  end
end

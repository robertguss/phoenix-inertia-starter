defmodule StarterKitWeb.Auth.MagicLinkController do
  @moduledoc """
  Passwordless magic-link sign-in (KTD3, Pattern B). `new`/`create` render and
  handle the request form; `callback` is the plain GET the emailed link points at
  (`/auth/magic-link?token=...`). Requesting a link is enumeration-safe — it
  always reports success whether or not the email exists.
  """
  use StarterKitWeb, :controller

  alias AshAuthentication.Plug.Helpers
  alias StarterKit.Accounts

  def new(conn, _params) do
    render_inertia(conn, "auth/magic-link")
  end

  def create(conn, %{"email" => email}) do
    _ = Accounts.request_magic_link(email, authorize?: false)

    conn
    |> put_flash(:info, "If that email has an account, a sign-in link is on its way.")
    |> redirect(to: ~p"/sign-in")
  end

  def callback(conn, %{"token" => token}) do
    case Accounts.sign_in_with_magic_link(token, authorize?: false) do
      {:ok, user} ->
        conn
        |> Helpers.store_in_session(user)
        |> put_flash(:info, "You are signed in.")
        |> redirect(to: ~p"/")

      {:error, _reason} ->
        conn
        |> put_flash(:error, "That magic link is invalid or has expired.")
        |> redirect(to: ~p"/sign-in")
    end
  end
end

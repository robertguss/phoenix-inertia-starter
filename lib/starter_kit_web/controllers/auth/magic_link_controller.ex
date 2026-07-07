defmodule StarterKitWeb.Auth.MagicLinkController do
  @moduledoc """
  Passwordless magic-link sign-in (KTD3, Pattern B). `new`/`create` render and
  handle the request form. The emailed link (`GET /auth/magic-link?token=...`)
  only *shows* a confirm button via `show` — the token is consumed on the
  explicit `confirm` POST, so email scanners and link prefetchers can't silently
  sign anyone in. Requesting a link is enumeration-safe — it always reports
  success whether or not the email exists.
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

  def show(conn, %{"token" => token}) do
    conn
    |> assign_prop(:token, token)
    |> render_inertia("auth/magic-link-confirm")
  end

  def confirm(conn, %{"token" => token}) do
    case Accounts.sign_in_with_magic_link(token, authorize?: false) do
      {:ok, user} ->
        conn
        # store_in_session does not renew on its own; renew to rotate the session
        # id on privilege change (F26).
        |> Helpers.store_in_session(user)
        |> configure_session(renew: true)
        |> put_flash(:info, "You are signed in.")
        |> redirect(to: ~p"/")

      {:error, _reason} ->
        conn
        |> put_flash(:error, "That magic link is invalid or has expired.")
        |> redirect(to: ~p"/sign-in")
    end
  end
end

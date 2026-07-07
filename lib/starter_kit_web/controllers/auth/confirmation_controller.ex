defmodule StarterKitWeb.Auth.ConfirmationController do
  @moduledoc """
  Email-address confirmation (KTD3, Pattern B). The confirmation strategy is
  configured with `require_interaction?`, so the emailed link (`GET
  /auth/confirm?token=...`) only *shows* a confirm button — the actual
  confirmation happens on the `POST`, which stops email scanners and link
  prefetchers from silently confirming.
  """
  use StarterKitWeb, :controller

  alias StarterKit.Accounts.User

  def show(conn, %{"token" => token}) do
    conn
    |> assign_prop(:token, token)
    |> render_inertia("auth/confirm")
  end

  def confirm(conn, %{"token" => token}) do
    strategy = AshAuthentication.Info.strategy!(User, :confirm_new_user)

    case AshAuthentication.Strategy.action(strategy, :confirm, %{"confirm" => token},
           authorize?: false
         ) do
      {:ok, _user} ->
        conn
        |> put_flash(:info, "Your email is confirmed — you can now sign in.")
        |> redirect(to: ~p"/sign-in")

      {:error, _reason} ->
        conn
        |> put_flash(:error, "That confirmation link is invalid or has expired.")
        |> redirect(to: ~p"/sign-in")
    end
  end
end

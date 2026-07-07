defmodule StarterKitWeb.Auth.PasswordResetController do
  @moduledoc """
  Forgot-password / reset flow (KTD3, Pattern B). `new`/`create` handle the
  "email me a link" request (enumeration-safe); `edit`/`update` are the emailed
  link target (`GET /auth/reset-password?token=...`) and its submit, which
  exchanges the token for a new password via the password strategy's `:reset`
  action.
  """
  use StarterKitWeb, :controller

  alias StarterKit.Accounts
  alias StarterKit.Accounts.User

  def new(conn, _params) do
    render_inertia(conn, "auth/forgot-password")
  end

  def create(conn, %{"email" => email}) do
    _ = Accounts.request_password_reset(email, authorize?: false)

    conn
    |> put_flash(:info, "If that email has an account, reset instructions are on the way.")
    |> redirect(to: ~p"/sign-in")
  end

  def edit(conn, %{"token" => token}) do
    conn
    |> assign_prop(:token, token)
    |> render_inertia("auth/reset-password")
  end

  def update(conn, %{
        "token" => token,
        "password" => password,
        "password_confirmation" => password_confirmation
      }) do
    strategy = AshAuthentication.Info.strategy!(User, :password)

    params = %{
      "reset_token" => token,
      "password" => password,
      "password_confirmation" => password_confirmation
    }

    case AshAuthentication.Strategy.action(strategy, :reset, params, authorize?: false) do
      {:ok, _user} ->
        conn
        |> put_flash(:info, "Your password has been reset — please sign in.")
        |> redirect(to: ~p"/sign-in")

      {:error, error} ->
        if invalid_token?(error) do
          # A bad/expired token is not a form-field problem — mirror the
          # confirmation flow: safe-fail back to sign-in with a flash.
          conn
          |> put_flash(
            :error,
            "That password-reset link is invalid or has expired. Request a new one."
          )
          |> redirect(to: ~p"/sign-in")
        else
          # Ordinary validation errors (password too short / mismatch) re-render the
          # form with field errors, same as registration.
          conn
          |> assign_errors(error)
          |> assign_prop(:token, token)
          |> render_inertia("auth/reset-password")
        end
    end
  end

  # The reset action returns InvalidToken either bare or nested inside an
  # Ash.Error.* wrapper's `:errors` list depending on the failure path.
  defp invalid_token?(%AshAuthentication.Errors.InvalidToken{}), do: true

  defp invalid_token?(%{errors: errors}) when is_list(errors),
    do: Enum.any?(errors, &invalid_token?/1)

  defp invalid_token?(_), do: false
end

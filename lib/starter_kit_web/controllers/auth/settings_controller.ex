defmodule StarterKitWeb.Auth.SettingsController do
  @moduledoc """
  Authenticated account settings (KTD3, Pattern B). Currently a password change
  that requires the current password (the `change_password` action validates it).
  Behind `:require_authenticated`, so `current_user` is always present.
  """
  use StarterKitWeb, :controller

  alias AshPhoenix.Inertia.Error, as: InertiaError
  alias StarterKit.Accounts

  def edit(conn, _params) do
    render_inertia(conn, "auth/settings")
  end

  def update_password(conn, %{
        "current_password" => current_password,
        "password" => password,
        "password_confirmation" => password_confirmation
      }) do
    user = conn.assigns.current_user

    case Accounts.change_password(user, current_password, password, password_confirmation,
           actor: user,
           authorize?: false
         ) do
      {:ok, _user} ->
        conn
        |> put_flash(:info, "Your password has been updated.")
        |> redirect(to: ~p"/settings")

      {:error, error} ->
        conn
        |> assign_errors(password_change_errors(error))
        |> render_inertia("auth/settings")
    end
  end

  # A wrong current password surfaces as an opaque `AuthenticationFailed`, which
  # has no form-field mapping (so it flattens to `%{}`). Fall back to a message on
  # the current-password field; genuine field errors (mismatch, length) map as-is.
  defp password_change_errors(error) do
    case InertiaError.to_errors(error) do
      map when map_size(map) == 0 -> %{"current_password" => "Current password is incorrect."}
      map -> map
    end
  end
end

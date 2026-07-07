defmodule StarterKitWeb.Auth.RegistrationController do
  @moduledoc """
  New-user registration (KTD3, Pattern B). Registration creates an unconfirmed
  user and the confirmation add-on emails a link; the user is *not* signed in
  until they confirm (password sign-in requires a confirmed email), so a
  successful registration lands on a "check your email" page.
  """
  use StarterKitWeb, :controller

  alias StarterKit.Accounts

  def new(conn, _params) do
    render_inertia(conn, "auth/register")
  end

  def create(conn, %{
        "email" => email,
        "password" => password,
        "password_confirmation" => password_confirmation
      }) do
    case Accounts.register_with_password(email, password, password_confirmation,
           authorize?: false
         ) do
      {:ok, _user} ->
        redirect(conn, to: ~p"/register/confirm-pending")

      {:error, error} ->
        conn
        |> assign_errors(error)
        |> render_inertia("auth/register")
    end
  end

  def confirm_pending(conn, _params) do
    render_inertia(conn, "auth/confirm-pending")
  end
end

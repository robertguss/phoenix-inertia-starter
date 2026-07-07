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
        if duplicate_email?(error) do
          # Enumeration-safe: a taken email lands on the same confirm-pending page as
          # a fresh signup, so the form can't probe which emails already exist. The
          # existing account is untouched — no user created, no email sent (F25).
          redirect(conn, to: ~p"/register/confirm-pending")
        else
          conn
          |> assign_errors(error)
          |> render_inertia("auth/register")
        end
    end
  end

  def confirm_pending(conn, _params) do
    render_inertia(conn, "auth/confirm-pending")
  end

  # True only for the unique-email identity violation (Ash surfaces "has already
  # been taken" on :email). Every other validation error still re-renders the form.
  defp duplicate_email?(%Ash.Error.Invalid{errors: errors}) do
    Enum.any?(
      errors,
      &match?(
        %Ash.Error.Changes.InvalidAttribute{field: :email, message: "has already been taken"},
        &1
      )
    )
  end

  defp duplicate_email?(_), do: false
end

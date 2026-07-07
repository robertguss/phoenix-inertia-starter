defmodule StarterKit.Accounts.User.Senders.SendPasswordResetEmail do
  @moduledoc """
  Sends a password reset email
  """

  use AshAuthentication.Sender

  import Swoosh.Email

  alias StarterKit.Mailer

  @impl true
  def send(user, token, _) do
    new()
    |> from(Application.fetch_env!(:starter_kit, :email_from))
    |> to(to_string(user.email))
    |> subject("Reset your password")
    |> html_body(body(token: token))
    |> Mailer.deliver!()
  end

  defp body(params) do
    # KTD3 scheme: reset form is a GET at /auth/reset-password?token=... (U5).
    url =
      StarterKitWeb.Endpoint.url() <>
        "/auth/reset-password?" <> URI.encode_query(token: params[:token])

    """
    <p>Click this link to reset your password:</p>
    <p><a href="#{url}">#{url}</a></p>
    """
  end
end

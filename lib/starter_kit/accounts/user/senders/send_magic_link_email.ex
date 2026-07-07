defmodule StarterKit.Accounts.User.Senders.SendMagicLinkEmail do
  @moduledoc """
  Sends a magic link email
  """

  use AshAuthentication.Sender

  import Swoosh.Email
  alias StarterKit.Mailer

  @impl true
  def send(user_or_email, token, _) do
    # if you get a user, its for a user that already exists.
    # if you get an email, then the user does not yet exist.

    email =
      case user_or_email do
        %{email: email} -> email
        email -> email
      end

    new()
    |> from(Application.fetch_env!(:starter_kit, :email_from))
    |> to(to_string(email))
    |> subject("Your login link")
    |> html_body(body(token: token, email: email))
    |> Mailer.deliver!()
  end

  defp body(params) do
    # KTD3: the magic-link callback is a plain GET at /auth/magic-link?token=...
    # (route built in U5). Built as a plain string so the domain layer stays
    # decoupled from the web router's compile-time verified routes.
    url =
      StarterKitWeb.Endpoint.url() <>
        "/auth/magic-link?" <> URI.encode_query(token: params[:token])

    # Escape the email before interpolating — it comes from user input and lands
    # in HTML. The URL is already query-encoded.
    email = params[:email] |> to_string() |> Plug.HTML.html_escape()

    """
    <p>Hello, #{email}! Click this link to sign in:</p>
    <p><a href="#{url}">#{url}</a></p>
    """
  end
end

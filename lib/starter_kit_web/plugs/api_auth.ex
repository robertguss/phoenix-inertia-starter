defmodule StarterKitWeb.Plugs.ApiAuth do
  @moduledoc """
  Sets the Ash actor for API requests from either an API key or a JWT bearer token
  (R14) — both arrive as `Authorization: Bearer <token>`. The key is tried first;
  anything that isn't a valid key falls through to the JWT check (`on_error` is a
  no-op so the pipeline never halts here). A missing or invalid credential simply
  leaves the actor unset, and resource policies reject the request.

  `AshAuthentication.Strategy.ApiKey.Plug` is initialised per-request rather than at
  compile time so this plug does not depend on `StarterKit.Accounts.User` being
  compiled first.
  """
  alias AshAuthentication.Plug.Helpers
  alias AshAuthentication.Strategy.ApiKey

  def init(opts), do: opts

  def call(conn, _opts) do
    conn
    |> put_api_key_actor()
    |> maybe_put_bearer_actor()
    |> Helpers.set_actor(:user)
  end

  defp put_api_key_actor(conn) do
    opts =
      ApiKey.Plug.init(
        resource: StarterKit.Accounts.User,
        required?: false,
        on_error: &__MODULE__.ignore_key_error/2
      )

    ApiKey.Plug.call(conn, opts)
  end

  defp maybe_put_bearer_actor(%{assigns: %{current_user: user}} = conn) when not is_nil(user),
    do: conn

  defp maybe_put_bearer_actor(conn), do: Helpers.retrieve_from_bearer(conn, :starter_kit)

  @doc false
  # A bad/absent API key is not an error here — the JWT check and resource policies
  # handle unauthenticated requests. Pass the connection through untouched.
  def ignore_key_error(conn, _error), do: conn
end

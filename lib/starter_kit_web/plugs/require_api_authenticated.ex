defmodule StarterKitWeb.Plugs.RequireApiAuthenticated do
  @moduledoc """
  Halts unsafe JSON:API requests that have no authenticated actor.

  Read-only routes still fall through to Ash policies so public documentation and
  resource-specific read rules keep working. Writes need an actor before AshJsonApi
  reaches resource changes such as `relate_actor/1`.
  """
  import Plug.Conn

  @safe_methods ~w(GET HEAD OPTIONS)

  def init(opts), do: opts

  def call(%{method: method} = conn, _opts) when method in @safe_methods, do: conn

  def call(%{assigns: %{current_user: user}} = conn, _opts) when not is_nil(user), do: conn

  def call(conn, _opts) do
    conn
    |> put_resp_content_type("application/vnd.api+json")
    |> send_resp(401, Jason.encode!(error_document()))
    |> halt()
  end

  defp error_document do
    %{
      errors: [
        %{
          status: "401",
          title: "Unauthorized",
          detail: "Authentication is required for this endpoint."
        }
      ]
    }
  end
end

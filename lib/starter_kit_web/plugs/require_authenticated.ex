defmodule StarterKitWeb.Plugs.RequireAuthenticated do
  @moduledoc """
  Halts anonymous requests to protected routes, redirecting to the sign-in page
  with a flash. Relies on `FetchCurrentUser` having run earlier in the pipeline.
  """
  import Plug.Conn, only: [halt: 1]
  import Phoenix.Controller, only: [put_flash: 3, redirect: 2]
  use StarterKitWeb, :verified_routes

  def init(opts), do: opts

  def call(conn, _opts) do
    if conn.assigns[:current_user] do
      conn
    else
      conn
      |> put_flash(:error, "You must sign in to continue.")
      |> redirect(to: ~p"/sign-in")
      |> halt()
    end
  end
end

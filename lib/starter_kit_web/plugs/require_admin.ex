defmodule StarterKitWeb.Plugs.RequireAdmin do
  @moduledoc """
  Gates the LiveView admin surfaces (AshAdmin, LiveDashboard). Open in development
  (`dev_routes`), admin-only everywhere else (R5, AE4): an anonymous request is
  redirected to sign-in; an authenticated non-admin gets a bare 404 so the admin
  surface stays hidden. Relies on `FetchCurrentUser` populating `current_user`.
  """
  import Plug.Conn, only: [send_resp: 3, halt: 1]
  # PRUNE:WEB
  import Phoenix.Controller, only: [redirect: 2]
  use StarterKitWeb, :verified_routes
  # PRUNE:END

  def init(opts), do: opts

  def call(conn, _opts) do
    cond do
      Application.get_env(:starter_kit, :dev_routes, false) ->
        conn

      match?(%{admin?: true}, conn.assigns[:current_user]) ->
        conn

      # PRUNE:WEB
      is_nil(conn.assigns[:current_user]) ->
        conn |> redirect(to: ~p"/sign-in") |> halt()

      # PRUNE:END
      true ->
        conn |> send_resp(404, "Not Found") |> halt()
    end
  end
end

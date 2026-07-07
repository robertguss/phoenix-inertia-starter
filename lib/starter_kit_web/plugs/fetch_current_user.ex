defmodule StarterKitWeb.Plugs.FetchCurrentUser do
  @moduledoc """
  Loads the signed-in user from the session into `conn.assigns.current_user`
  (or `nil` when signed out) and sets it as the Ash actor for the request.

  Runs early in the browser pipelines so controllers, policies, and downstream
  plugs can all rely on `current_user` and the actor being set.
  """
  alias AshAuthentication.Plug.Helpers

  def init(opts), do: opts

  def call(conn, _opts) do
    conn
    |> Helpers.retrieve_from_session(:starter_kit)
    |> Helpers.set_actor(:user)
  end
end

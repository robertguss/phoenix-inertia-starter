defmodule StarterKitWeb.PageController do
  @moduledoc """
  Renders the home page as an Inertia component. `assign_prop/3` + `render_inertia/2`
  come from `Inertia.Controller` (imported in the `:controller` helper).
  """
  use StarterKitWeb, :controller

  def home(conn, _params) do
    conn
    |> assign_prop(:message, "Welcome to the Phoenix Starter Kit")
    |> render_inertia("home")
  end
end

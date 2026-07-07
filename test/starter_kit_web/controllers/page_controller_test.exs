defmodule StarterKitWeb.PageControllerTest do
  use StarterKitWeb.ConnCase, async: true

  import Inertia.Testing

  test "GET / renders the home Inertia component with its props", %{conn: conn} do
    conn = get(conn, ~p"/")

    assert inertia_component(conn) == "home"
    assert %{message: "Welcome to the Phoenix Starter Kit"} = inertia_props(conn)
  end
end

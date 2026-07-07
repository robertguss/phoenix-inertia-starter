defmodule StarterKitWeb.Plugs.InertiaShare do
  @moduledoc """
  Shares the current user as a global Inertia prop (`current_user`) on every
  page, so React pages render auth state without each controller passing it.

  Serializes to a minimal public map — never the full Ash resource, so secrets
  like `hashed_password` can never leak into a page payload.
  """
  import Inertia.Controller, only: [assign_prop: 3]

  def init(opts), do: opts

  def call(conn, _opts) do
    assign_prop(conn, :current_user, serialize(conn.assigns[:current_user]))
  end

  defp serialize(nil), do: nil
  defp serialize(user), do: %{id: user.id, email: to_string(user.email)}
end

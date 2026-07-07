defmodule StarterKitWeb.AshAdminActorPlug do
  @moduledoc """
  Feeds the signed-in AshAuthentication user to AshAdmin as the Ash actor (KTD-R6).

  The pinned AshAdmin resolves its actor solely from its own "act as" selector
  cookies (via `AshAdmin.ActorPlug.Plug`), defaulting to `nil`. It does NOT read the
  actor that `FetchCurrentUser` set with `Ash.PlugHelpers.set_actor` on the conn.
  So with AshAdmin's "authorizing" toggle on, reads would run with a nil actor and
  every policy would deny — the empty/forbidden-list symptom.

  This override delegates to the default plug for everything, then sets the actor to
  the current signed-in user, resolved from the session with AshAuthentication's own
  LiveView helper (`assign_new_resources/4`, which also honours token presence). With
  the admin bypass policy on User/Note, an admin then sees and manages every row.

  Registered via `config :ash_admin, :actor_plug`. Only `actor_assigns/2` is a live
  code path here: it runs in `AshAdmin.PageLive.mount/3`. `set_actor_session/1` (the
  Plug entrypoint) is not wired into any pipeline, so it just delegates to the default
  to preserve the built-in "act as" selector for anyone who does plug it in.
  """
  @behaviour AshAdmin.ActorPlug

  alias AshAdmin.ActorPlug.Plug, as: DefaultActorPlug
  alias AshAuthentication.Plug.Helpers

  @impl true
  def set_actor_session(conn), do: DefaultActorPlug.set_actor_session(conn)

  @impl true
  def actor_assigns(socket, session) do
    base = DefaultActorPlug.actor_assigns(socket, session)

    socket =
      Helpers.assign_new_resources(
        socket,
        session,
        &Phoenix.Component.assign_new/3,
        otp_app: :starter_kit
      )

    case socket.assigns[:current_user] do
      nil -> base
      user -> Keyword.put(base, :actor, user)
    end
  end
end

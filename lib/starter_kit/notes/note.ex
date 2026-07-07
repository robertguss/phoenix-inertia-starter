# DEMO: Example vertical slice (Notes). Everything tagged `# DEMO:` is removed by
# `bin/remove_demo`; this whole file is deleted.
defmodule StarterKit.Notes.Note do
  @moduledoc """
  Demo Notes resource (R23) — the pattern corpus a newborn learns from: a
  user-owned resource with owner-only policies, exposed to both the Inertia web UI
  (U5 controllers) and JSON:API (U7 auth). `bin/remove_demo` deletes it wholesale.
  """
  use Ash.Resource,
    otp_app: :starter_kit,
    domain: StarterKit.Notes,
    data_layer: AshPostgres.DataLayer,
    authorizers: [Ash.Policy.Authorizer],
    extensions: [AshJsonApi.Resource]

  postgres do
    table "notes"
    repo StarterKit.Repo
  end

  policies do
    # Any authenticated actor may create a note (it becomes theirs).
    policy action_type(:create) do
      authorize_if(actor_present())
    end

    # Read/update/destroy are owner-only. For reads this becomes a filter (you only
    # see your own notes); for writes a non-owner is forbidden.
    policy action_type([:read, :update, :destroy]) do
      authorize_if(relates_to_actor_via(:user))
    end
  end

  json_api do
    type "note"
  end

  attributes do
    uuid_primary_key(:id)

    attribute :title, :string do
      allow_nil?(false)
      public?(true)
      constraints(min_length: 1, max_length: 200)
    end

    attribute :body, :string do
      public?(true)
    end

    create_timestamp(:inserted_at)
    update_timestamp(:updated_at)
  end

  relationships do
    belongs_to :user, StarterKit.Accounts.User do
      allow_nil?(false)
    end
  end

  actions do
    defaults([:read, :destroy])

    create :create do
      primary? true
      accept([:title, :body])
      # Owns-on-create: the note belongs to whoever is acting.
      change(relate_actor(:user))
    end

    update :update do
      primary? true
      accept([:title, :body])
    end
  end
end

defmodule StarterKit.Accounts.ApiKey do
  @moduledoc """
  API keys for programmatic access (R14). Only a hash of the key is stored — the
  plaintext is available on `api_key.__metadata__.plaintext_api_key` immediately
  after creation and never again. The `starter_kit` prefix makes leaked keys
  detectable by secret scanners.
  """
  use Ash.Resource,
    otp_app: :starter_kit,
    domain: StarterKit.Accounts,
    data_layer: AshPostgres.DataLayer,
    authorizers: [Ash.Policy.Authorizer]

  postgres do
    table "api_keys"
    repo StarterKit.Repo
  end

  policies do
    bypass AshAuthentication.Checks.AshAuthenticationInteraction do
      description("AshAuthentication verifies keys during sign-in.")
      authorize_if(always())
    end

    # A user manages only their own keys.
    policy action_type([:read, :destroy]) do
      authorize_if(relates_to_actor_via(:user))
    end

    policy action_type(:create) do
      authorize_if(relating_to_actor(:user))
    end
  end

  attributes do
    uuid_primary_key(:id)

    attribute :api_key_hash, :binary do
      allow_nil?(false)
      sensitive?(true)
    end

    attribute :expires_at, :utc_datetime_usec do
      allow_nil?(false)
    end

    create_timestamp(:created_at)
  end

  relationships do
    belongs_to :user, StarterKit.Accounts.User do
      allow_nil?(false)
    end
  end

  actions do
    defaults([:read, :destroy])

    create :create do
      primary?(true)
      accept([:user_id, :expires_at])

      # The prefix must be `[a-z0-9]` (no underscore), so it can't be the `starter_kit`
      # app name verbatim. The birth script renames this concatenated form too.
      change(
        {AshAuthentication.Strategy.ApiKey.GenerateApiKey,
         prefix: :starterkit, hash: :api_key_hash}
      )
    end
  end

  identities do
    identity(:unique_api_key, [:api_key_hash])
  end

  calculations do
    calculate(:valid, :boolean, expr(expires_at > now()))
  end
end

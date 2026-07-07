defmodule StarterKit.Accounts.Token do
  @moduledoc """
  Token resource backing AshAuthentication — stores JWTs, magic-link tokens, and
  confirmation tokens so they can be verified and revoked.
  """
  use Ash.Resource,
    otp_app: :starter_kit,
    domain: StarterKit.Accounts,
    data_layer: AshPostgres.DataLayer,
    authorizers: [Ash.Policy.Authorizer],
    extensions: [AshAuthentication.TokenResource, AshOban]

  policies do
    bypass(AshAuthentication.Checks.AshAuthenticationInteraction) do
      description("AshAuthentication can interact with the token resource")
      authorize_if(always())
    end
  end

  # Example AshOban trigger (R4). A polling scheduler — NOT a database hook: once a
  # day the scheduler runs the `where` query, finds expired tokens, and enqueues one
  # `:destroy` job per matching row. This keeps the tokens table from growing without
  # bound. It is the authoritative ash_oban usage example in this template.
  oban do
    triggers do
      trigger :expunge_expired_tokens do
        action(:destroy)
        where(expr(expires_at < now()))
        scheduler_cron("@daily")
        queue(:default)
        # Explicit module names keep enqueued jobs stable if the trigger is renamed.
        worker_module_name(StarterKit.Accounts.Token.AshOban.Worker.ExpungeExpiredTokens)
        scheduler_module_name(StarterKit.Accounts.Token.AshOban.Scheduler.ExpungeExpiredTokens)
      end
    end
  end

  postgres do
    table "tokens"
    repo StarterKit.Repo
  end

  attributes do
    attribute :jti, :string do
      primary_key?(true)
      public?(true)
      allow_nil?(false)
      sensitive?(true)
    end

    attribute :subject, :string do
      allow_nil?(false)
      public?(true)
    end

    attribute :expires_at, :utc_datetime do
      allow_nil?(false)
      public?(true)
    end

    attribute :purpose, :string do
      allow_nil?(false)
      public?(true)
    end

    attribute :extra_data, :map do
      public?(true)
    end

    create_timestamp(:created_at)
    update_timestamp(:updated_at)
  end

  actions do
    defaults([:read, :destroy])

    read :expired do
      description("Look up all expired tokens.")
      filter(expr(expires_at < now()))
    end

    read :get_token do
      description("Look up a token by JTI or token, and an optional purpose.")
      get?(true)
      argument(:token, :string, sensitive?: true)
      argument(:jti, :string, sensitive?: true)
      argument(:purpose, :string, sensitive?: false)

      prepare(AshAuthentication.TokenResource.GetTokenPreparation)
    end

    action :revoked?, :boolean do
      description("Returns true if a revocation token is found for the provided token")
      argument(:token, :string, sensitive?: true)
      argument(:jti, :string, sensitive?: true)

      run(AshAuthentication.TokenResource.IsRevoked)
    end

    create :revoke_token do
      description(
        "Revoke a token. Creates a revocation token corresponding to the provided token."
      )

      accept([:extra_data])
      argument(:token, :string, allow_nil?: false, sensitive?: true)

      change(AshAuthentication.TokenResource.RevokeTokenChange)
    end

    create :revoke_jti do
      description(
        "Revoke a token by JTI. Creates a revocation token corresponding to the provided jti."
      )

      accept([:extra_data])
      argument(:subject, :string, allow_nil?: false, sensitive?: true)
      argument(:jti, :string, allow_nil?: false, sensitive?: true)

      change(AshAuthentication.TokenResource.RevokeJtiChange)
    end

    create :store_token do
      description("Stores a token used for the provided purpose.")
      accept([:extra_data, :purpose])
      argument(:token, :string, allow_nil?: false, sensitive?: true)
      change(AshAuthentication.TokenResource.StoreTokenChange)
    end

    destroy :expunge_expired do
      description("Deletes expired tokens.")
      change(filter(expr(expires_at < now())))
    end

    update :revoke_all_stored_for_subject do
      description("Revokes all stored tokens for a specific subject.")
      accept([:extra_data])
      argument(:subject, :string, allow_nil?: false, sensitive?: true)
      change(AshAuthentication.TokenResource.RevokeAllStoredForSubjectChange)
    end
  end
end

defmodule StarterKit.Accounts.User do
  @moduledoc """
  User resource with AshAuthentication password (bcrypt), magic-link, and
  email-confirmation strategies. Password sign-in requires a confirmed email.
  """
  use Ash.Resource,
    otp_app: :starter_kit,
    domain: StarterKit.Accounts,
    data_layer: AshPostgres.DataLayer,
    authorizers: [Ash.Policy.Authorizer],
    extensions: [AshAuthentication, AshJsonApi.Resource, AshOban]

  authentication do
    add_ons do
      log_out_everywhere do
        apply_on_password_change? true
      end

      confirmation :confirm_new_user do
        monitor_fields [:email]
        confirm_on_create? true
        confirm_on_update? false
        require_interaction? true
        # F24 invariant: stays true. A pre-registration squat is NOT a takeover —
        # register_with_password's token is discarded by RegistrationController
        # (never sessioned) and require_confirmed_with :confirmed_at blocks password
        # sign-in until confirmation — so do NOT disable this without a vetted
        # password-clearing upsert.
        prevent_hijacking? true
        confirmed_at_field :confirmed_at
        auto_confirm_actions [:sign_in_with_magic_link, :reset_password_with_token]
        sender StarterKit.Accounts.User.Senders.SendNewUserConfirmationEmail
      end
    end

    tokens do
      enabled? true
      token_resource StarterKit.Accounts.Token
      signing_secret StarterKit.Secrets
      store_all_tokens? true
      require_token_presence_for_authentication? true
    end

    strategies do
      password :password do
        identity_field :email
        hash_provider AshAuthentication.BcryptProvider
        # Anti-squatting: password sign-in only works once the email is confirmed.
        # Magic-link sign-in inherently proves ownership, so it auto-confirms (see
        # the confirmation add-on's auto_confirm_actions above).
        require_confirmed_with :confirmed_at

        resettable do
          sender StarterKit.Accounts.User.Senders.SendPasswordResetEmail
          # these configurations will be the default in a future release
          password_reset_action_name :reset_password_with_token
          request_password_reset_action_name :request_password_reset_token
        end
      end

      remember_me :remember_me

      magic_link do
        identity_field :email
        registration_enabled? true
        # The interstitial (GET shows, POST consumes) is enforced by
        # MagicLinkController, not this flag — the controller calls the
        # sign_in_with_magic_link action directly, which the flag does not gate.
        require_interaction? true

        sender StarterKit.Accounts.User.Senders.SendMagicLinkEmail
      end

      # API-key auth (R14). The plug validates keys against `valid_api_keys` (only
      # unexpired ones, per the relationship filter).
      api_key do
        api_key_relationship :valid_api_keys
      end
    end
  end

  policies do
    # KTD-R6: resource-level admin bypass. An actor with admin? == true passes ALL
    # policies (read + the default-deny create/update/destroy), so AshAdmin — and any
    # authenticated surface — can list and manage every user row. This is deliberately
    # NOT action-type scoped: admin credentials via any authenticated surface grant
    # full CRUD. That opens no path for a non-admin — admin? is server-set and not a
    # public attribute (never accepted from forms/APIs), so the power stays admin-gated.
    bypass actor_attribute_equals(:admin?, true) do
      authorize_if(always())
    end

    bypass(AshAuthentication.Checks.AshAuthenticationInteraction) do
      authorize_if(always())
    end

    # API/general reads require an authenticated actor, who only sees themselves.
    policy action_type(:read) do
      forbid_unless(actor_present())
      authorize_if(expr(id == ^actor(:id)))
    end
  end

  # KTD-R3: a polling scheduler (same pattern as Token's expunge trigger) that
  # once a day destroys users still unconfirmed 7 days after creation. This makes
  # a pre-registration email squat (F5) self-heal instead of locking the real
  # owner out forever. Runs unauthorized via `config :ash_oban, authorize?: false`.
  oban do
    triggers do
      trigger :expire_unconfirmed_users do
        action(:destroy)
        where(expr(is_nil(confirmed_at) and inserted_at < ago(7, :day)))
        scheduler_cron("@daily")
        queue(:default)
        # Explicit module names keep enqueued jobs stable if the trigger is renamed.
        worker_module_name(StarterKit.Accounts.User.AshOban.Worker.ExpireUnconfirmedUsers)
        scheduler_module_name(StarterKit.Accounts.User.AshOban.Scheduler.ExpireUnconfirmedUsers)
      end
    end
  end

  # Exposed via JSON:API (R13). Routes are declared on the domain; only public
  # attributes (id, email) are serialized — hashed_password/admin? are not public.
  json_api do
    type "user"
  end

  postgres do
    table "users"
    repo StarterKit.Repo
  end

  attributes do
    uuid_primary_key(:id)

    attribute :email, :ci_string do
      allow_nil?(false)
      public?(true)
    end

    attribute :hashed_password, :string do
      sensitive?(true)
    end

    attribute(:confirmed_at, :utc_datetime_usec)

    # Gates production access to the admin surfaces (R5, AE4). Not public — set it
    # from a seed, the console, or AshAdmin, never from user-facing forms/APIs.
    attribute :admin?, :boolean do
      allow_nil?(false)
      default(false)
      public?(false)
    end

    # Creation timestamp — flows through the magic-link upsert's initial insert and
    # is the clock the expire_unconfirmed_users trigger measures the 7-day window against.
    create_timestamp(:inserted_at)
  end

  relationships do
    # Only unexpired keys count for authentication (the api_key strategy reads this).
    has_many :valid_api_keys, StarterKit.Accounts.ApiKey do
      filter(expr(valid))
    end
  end

  actions do
    # :destroy backs the expire_unconfirmed_users AshOban trigger.
    defaults([:read, :destroy])

    read :get_by_subject do
      description("Get a user by the subject claim in a JWT")
      argument(:subject, :string, allow_nil?: false)
      get?(true)
      prepare(AshAuthentication.Preparations.FilterBySubject)
    end

    update :change_password do
      # Use this action to allow users to change their password by providing
      # their current password and a new password.

      require_atomic?(false)
      accept([])
      argument(:current_password, :string, sensitive?: true, allow_nil?: false)

      argument(:password, :string,
        sensitive?: true,
        allow_nil?: false,
        constraints: [min_length: 8]
      )

      argument(:password_confirmation, :string, sensitive?: true, allow_nil?: false)

      validate(confirm(:password, :password_confirmation))

      validate(
        {AshAuthentication.Strategy.Password.PasswordValidation,
         strategy_name: :password, password_argument: :current_password}
      )

      change({AshAuthentication.Strategy.Password.HashPasswordChange, strategy_name: :password})
    end

    read :sign_in_with_password do
      description("Attempt to sign in using a email and password.")
      get?(true)

      argument :email, :ci_string do
        description("The email to use for retrieving the user.")
        allow_nil?(false)
      end

      argument :password, :string do
        description("The password to check for the matching user.")
        allow_nil?(false)
        sensitive?(true)
      end

      # validates the provided email and password and generates a token
      prepare(AshAuthentication.Strategy.Password.SignInPreparation)

      metadata :token, :string do
        description("A JWT that can be used to authenticate the user.")
        allow_nil?(false)
      end
    end

    read :sign_in_with_token do
      # In the generated sign in components, we validate the
      # email and password directly in the LiveView
      # and generate a short-lived token that can be used to sign in over
      # a standard controller action, exchanging it for a standard token.
      # This action performs that exchange. If you do not use the generated
      # liveviews, you may remove this action, and set
      # `sign_in_tokens_enabled? false` in the password strategy.

      description("Attempt to sign in using a short-lived sign in token.")
      get?(true)

      argument :token, :string do
        description("The short-lived sign in token.")
        allow_nil?(false)
        sensitive?(true)
      end

      # validates the provided sign in token and generates a token
      prepare(AshAuthentication.Strategy.Password.SignInWithTokenPreparation)

      metadata :token, :string do
        description("A JWT that can be used to authenticate the user.")
        allow_nil?(false)
      end
    end

    create :register_with_password do
      description("Register a new user with a email and password.")

      argument :email, :ci_string do
        allow_nil?(false)
      end

      argument :password, :string do
        description("The proposed password for the user, in plain text.")
        allow_nil?(false)
        constraints(min_length: 8)
        sensitive?(true)
      end

      argument :password_confirmation, :string do
        description("The proposed password for the user (again), in plain text.")
        allow_nil?(false)
        sensitive?(true)
      end

      # Sets the email from the argument
      change(set_attribute(:email, arg(:email)))

      # Hashes the provided password
      change(AshAuthentication.Strategy.Password.HashPasswordChange)

      # Generates an authentication token for the user
      change(AshAuthentication.GenerateTokenChange)

      # validates that the password matches the confirmation
      validate(AshAuthentication.Strategy.Password.PasswordConfirmationValidation)

      metadata :token, :string do
        description("A JWT that can be used to authenticate the user.")
        allow_nil?(false)
      end
    end

    action :request_password_reset_token do
      description("Send password reset instructions to a user if they exist.")

      argument :email, :ci_string do
        allow_nil?(false)
      end

      # creates a reset token and invokes the relevant senders
      run({AshAuthentication.Strategy.Password.RequestPasswordReset, action: :get_by_email})
    end

    read :sign_in_with_api_key do
      description("Sign in using an API key (R14).")
      argument(:api_key, :string, allow_nil?: false)
      prepare(AshAuthentication.Strategy.ApiKey.SignInPreparation)
    end

    read :get_by_email do
      description("Looks up a user by their email")
      get_by(:email)
    end

    update :reset_password_with_token do
      argument :reset_token, :string do
        allow_nil?(false)
        sensitive?(true)
      end

      argument :password, :string do
        description("The proposed password for the user, in plain text.")
        allow_nil?(false)
        constraints(min_length: 8)
        sensitive?(true)
      end

      argument :password_confirmation, :string do
        description("The proposed password for the user (again), in plain text.")
        allow_nil?(false)
        sensitive?(true)
      end

      # validates the provided reset token
      validate(AshAuthentication.Strategy.Password.ResetTokenValidation)

      # validates that the password matches the confirmation
      validate(AshAuthentication.Strategy.Password.PasswordConfirmationValidation)

      # Hashes the provided password
      change(AshAuthentication.Strategy.Password.HashPasswordChange)

      # Generates an authentication token for the user
      change(AshAuthentication.GenerateTokenChange)
    end

    create :sign_in_with_magic_link do
      description("Sign in or register a user with magic link.")

      argument :token, :string do
        description("The token from the magic link that was sent to the user")
        allow_nil?(false)
      end

      argument :remember_me, :boolean do
        description("Whether to generate a remember me token")
        allow_nil?(true)
      end

      upsert?(true)
      upsert_identity(:unique_email)
      upsert_fields([:email])

      # Uses the information from the token to create or sign in the user
      change(AshAuthentication.Strategy.MagicLink.SignInChange)

      change(
        {AshAuthentication.Strategy.RememberMe.MaybeGenerateTokenChange,
         strategy_name: :remember_me}
      )

      metadata :token, :string do
        allow_nil?(false)
      end
    end

    action :request_magic_link do
      argument :email, :ci_string do
        allow_nil?(false)
      end

      run(AshAuthentication.Strategy.MagicLink.Request)
    end
  end

  identities do
    identity(:unique_email, [:email])
  end

  validations do
    # The email attribute is only a ci_string by default — add a format check so
    # registration rejects malformed addresses (exercised by a property test).
    validate match(:email, ~r/^[^@\s]+@[^@\s]+\.[^@\s]+$/) do
      message("must be a valid email address")
    end
  end
end

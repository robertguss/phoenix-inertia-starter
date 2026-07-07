defmodule StarterKitWeb.Router do
  use StarterKitWeb, :router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_flash
    plug :put_root_layout, html: {StarterKitWeb.Layouts, :root}
    plug :protect_from_forgery

    plug :put_secure_browser_headers,
         %{
           "content-security-policy" =>
             Application.compile_env(:starter_kit, :content_security_policy)
         }

    plug Inertia.Plug
    plug StarterKitWeb.Plugs.FetchCurrentUser
    plug StarterKitWeb.Plugs.InertiaShare
  end

  pipeline :api do
    plug :accepts, ["json"]
    # Sets the Ash actor from an API key or JWT bearer token (R14). Never halts;
    # resource policies decide access. `open_api`/`docs` carry no policy, so they
    # stay reachable without credentials.
    plug StarterKitWeb.Plugs.ApiAuth
  end

  # Gate for authenticated-only pages; redirects anonymous users to sign-in.
  pipeline :require_authenticated do
    plug StarterKitWeb.Plugs.RequireAuthenticated
  end

  # LiveView admin surfaces (AshAdmin, LiveDashboard) bring their own layouts, so
  # they use a dedicated pipeline instead of the Inertia `:browser` one.
  pipeline :admin_browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_flash

    plug :put_secure_browser_headers,
         %{
           "content-security-policy" =>
             Application.compile_env(:starter_kit, :admin_content_security_policy)
         }

    plug :protect_from_forgery
    plug StarterKitWeb.Plugs.FetchCurrentUser
  end

  pipeline :require_admin do
    plug StarterKitWeb.Plugs.RequireAdmin
  end

  scope "/", StarterKitWeb do
    pipe_through :browser

    get "/", PageController, :home

    # Auth (KTD3, Pattern B): plain controllers + Inertia pages, no LiveView.
    get "/sign-in", Auth.SessionController, :new
    post "/sign-in", Auth.SessionController, :create
    delete "/sign-out", Auth.SessionController, :delete

    get "/register", Auth.RegistrationController, :new
    post "/register", Auth.RegistrationController, :create
    get "/register/confirm-pending", Auth.RegistrationController, :confirm_pending

    get "/magic-link", Auth.MagicLinkController, :new
    post "/magic-link", Auth.MagicLinkController, :create

    get "/forgot-password", Auth.PasswordResetController, :new
    post "/forgot-password", Auth.PasswordResetController, :create

    # Emailed-link callbacks — the senders point at these exact paths (?token=...).
    get "/auth/magic-link", Auth.MagicLinkController, :callback
    get "/auth/confirm", Auth.ConfirmationController, :show
    post "/auth/confirm", Auth.ConfirmationController, :confirm
    get "/auth/reset-password", Auth.PasswordResetController, :edit
    post "/auth/reset-password", Auth.PasswordResetController, :update
  end

  scope "/", StarterKitWeb do
    pipe_through [:browser, :require_authenticated]

    get "/settings", Auth.SettingsController, :edit
    put "/settings/password", Auth.SettingsController, :update_password

    # DEMO: Notes vertical slice (R23). bin/remove_demo strips these NoteController routes.
    get "/notes", NoteController, :index
    get "/notes/new", NoteController, :new
    post "/notes", NoteController, :create
    get "/notes/:id/edit", NoteController, :edit
    put "/notes/:id", NoteController, :update
    delete "/notes/:id", NoteController, :delete
  end

  # JSON:API (R13, R14). The AshJsonApi router serves the resource routes plus the
  # generated OpenAPI spec at /api/v1/open_api; Swagger UI renders it at /api/v1/docs.
  # The `forward "/"` to the Ash router must stay last (it matches everything).
  scope "/api/v1" do
    pipe_through :api

    forward "/docs", OpenApiSpex.Plug.SwaggerUI, path: "/api/v1/open_api"
    forward "/", StarterKitWeb.ApiRouter
  end

  # Admin + observability surfaces (R5, R6). Mounted in every environment but gated
  # by :require_admin — open in dev, admin-only in prod (AE4).
  scope "/" do
    pipe_through [:admin_browser, :require_admin]

    import AshAdmin.Router
    import Phoenix.LiveDashboard.Router

    ash_admin("/admin")
    live_dashboard "/dashboard", metrics: StarterKitWeb.Telemetry
  end

  # The Swoosh mailbox preview is a development-only convenience (the Local adapter
  # only stores mail in dev). It stays in both flavors (KTD7).
  if Application.compile_env(:starter_kit, :dev_routes) do
    scope "/dev" do
      pipe_through [:fetch_session, :protect_from_forgery]

      forward "/mailbox", Plug.Swoosh.MailboxPreview
    end
  end
end

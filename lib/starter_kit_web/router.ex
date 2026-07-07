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
  end

  # Gate for authenticated-only pages; redirects anonymous users to sign-in.
  pipeline :require_authenticated do
    plug StarterKitWeb.Plugs.RequireAuthenticated
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
  end

  scope "/api", StarterKitWeb do
    pipe_through :api
  end

  # Enable LiveDashboard and Swoosh mailbox preview in development
  if Application.compile_env(:starter_kit, :dev_routes) do
    # If you want to use the LiveDashboard in production, you should put
    # it behind authentication and allow only admins to access it.
    # If your application does not have an admins-only section yet,
    # you can use Plug.BasicAuth to set up some basic authentication
    # as long as you are also using SSL (which you should anyway).
    import Phoenix.LiveDashboard.Router

    scope "/dev" do
      pipe_through [:fetch_session, :protect_from_forgery]

      live_dashboard "/dashboard", metrics: StarterKitWeb.Telemetry
      forward "/mailbox", Plug.Swoosh.MailboxPreview
    end
  end
end

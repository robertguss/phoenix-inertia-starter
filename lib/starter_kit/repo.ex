defmodule StarterKit.Repo do
  use Ecto.Repo,
    otp_app: :starter_kit,
    adapter: Ecto.Adapters.Postgres
end

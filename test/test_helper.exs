# `:playwright` browser E2E is excluded from the fast gate (KTD8); run it with
# `mix test --only playwright`.
ExUnit.start(exclude: [:playwright])
Ecto.Adapters.SQL.Sandbox.mode(StarterKit.Repo, :manual)

# Mimic (R17): mark modules that tests may mock. `Mimic.copy/1` must run before
# any stubbing. Tests stub/expect on StarterKit.Mailer to simulate delivery
# failures without sending real mail.
Mimic.copy(StarterKit.Mailer)

# PRUNE:WEB
# Boot the Playwright harness only when the :playwright tests are actually selected,
# so the fast gate never touches the browser binaries.
if :playwright in (ExUnit.configuration()[:include] || []) do
  {:ok, _} = PhoenixTest.Playwright.Supervisor.start_link()
  Application.put_env(:phoenix_test, :base_url, StarterKitWeb.Endpoint.url())
end

# PRUNE:END

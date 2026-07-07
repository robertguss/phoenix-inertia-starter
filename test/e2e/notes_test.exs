defmodule StarterKitWeb.E2E.NotesTest do
  @moduledoc """
  Browser E2E smoke (R17, AE2, KTD8): a signed-in user creates a note through the
  real Inertia UI in a headless browser. Tagged `:playwright` and excluded from the
  fast gate; CI's birth-matrix web leg runs it via `mix test --only playwright`.
  `bin/new_project` deletes `test/e2e/` for the --api flavor.
  """
  use PhoenixTest.Playwright.Case, async: false

  @moduletag :playwright

  @password "password1234"

  setup do
    # Seeded directly (a confirmed user); the shared sandbox makes it visible to the
    # browser session PhoenixTest.Playwright.Case runs under.
    user =
      Ash.Seed.seed!(StarterKit.Accounts.User, %{
        email: "e2e@example.com",
        hashed_password: Bcrypt.hash_pwd_salt(@password),
        confirmed_at: DateTime.utc_now()
      })

    %{user: user}
  end

  test "signs in and creates a note behind auth", %{conn: conn, user: user} do
    conn
    |> visit("/sign-in")
    |> fill_in("Email", with: to_string(user.email))
    |> fill_in("Password", with: @password)
    |> click_button("Sign in")
    |> visit("/notes")
    |> click_link("New note")
    |> fill_in("Title", with: "Written in a browser")
    |> click_button("Create")
    |> assert_has("td", text: "Written in a browser")
  end
end

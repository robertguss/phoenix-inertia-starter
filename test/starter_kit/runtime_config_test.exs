defmodule StarterKit.RuntimeConfigTest do
  # AE5 / R7: production boot validates required environment variables and fails
  # fast, naming what is missing. `Config.Reader.read!/2` evaluates config/runtime.exs
  # in isolation with `env: :prod`, exercising the real `env!` guard.
  #
  # async: false — the tests mutate process-global environment variables.
  use ExUnit.Case, async: false

  # Every var the prod block funnels through `env!`. Order does not matter here —
  # each test sets all of them valid and drops exactly one, so the guard under
  # test is the only one that can fail.
  @required ~w(DATABASE_URL SECRET_KEY_BASE PHX_HOST TOKEN_SIGNING_SECRET
               MAILGUN_API_KEY MAILGUN_DOMAIN)

  @valid %{
    "DATABASE_URL" => "ecto://user:pass@localhost/starter_kit",
    "SECRET_KEY_BASE" => String.duplicate("a", 64),
    "PHX_HOST" => "example.com",
    "TOKEN_SIGNING_SECRET" => String.duplicate("b", 64),
    "MAILGUN_API_KEY" => "key-test",
    "MAILGUN_DOMAIN" => "mg.example.com"
  }

  setup do
    original = Map.new(@required, fn key -> {key, System.get_env(key)} end)

    on_exit(fn ->
      Enum.each(original, fn
        {key, nil} -> System.delete_env(key)
        {key, value} -> System.put_env(key, value)
      end)
    end)

    :ok
  end

  defp read_prod! do
    Config.Reader.read!("config/runtime.exs", env: :prod)
  end

  # Set every required var to a valid value, then drop the one under test so the
  # only guard that can fire is the one we're asserting on.
  defp put_valid_except(missing) do
    Enum.each(@valid, fn {key, value} ->
      if key == missing, do: System.delete_env(key), else: System.put_env(key, value)
    end)
  end

  for var <- @required do
    test "prod boot fails naming #{var} when it is the only one missing" do
      put_valid_except(unquote(var))

      assert_raise RuntimeError, ~r/#{unquote(var)}/, fn -> read_prod!() end
    end
  end

  test "prod boot succeeds when every required var is present" do
    Enum.each(@valid, fn {key, value} -> System.put_env(key, value) end)

    assert Keyword.keyword?(read_prod!())
  end
end

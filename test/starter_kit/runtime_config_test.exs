defmodule StarterKit.RuntimeConfigTest do
  # AE5 / R7: production boot validates required environment variables and fails
  # fast, naming what is missing. `Config.Reader.read!/2` evaluates config/runtime.exs
  # in isolation with `env: :prod`, exercising the real `env!` guard.
  #
  # async: false — the tests mutate process-global environment variables.
  use ExUnit.Case, async: false

  @required ~w(DATABASE_URL SECRET_KEY_BASE TOKEN_SIGNING_SECRET)

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

  test "boot fails naming DATABASE_URL when it is missing" do
    System.delete_env("DATABASE_URL")

    assert_raise RuntimeError, ~r/DATABASE_URL/, fn -> read_prod!() end
  end

  test "boot fails naming TOKEN_SIGNING_SECRET when it is the only one missing" do
    System.put_env("DATABASE_URL", "ecto://user:pass@localhost/starter_kit")
    System.put_env("SECRET_KEY_BASE", String.duplicate("a", 64))
    System.delete_env("TOKEN_SIGNING_SECRET")

    assert_raise RuntimeError, ~r/TOKEN_SIGNING_SECRET/, fn -> read_prod!() end
  end
end

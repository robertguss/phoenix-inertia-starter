defmodule StarterKit.Accounts.TokenAshObanTest do
  @moduledoc """
  R4: the `expunge_expired_tokens` AshOban trigger schedules a destroy job for each
  expired token and, when run, deletes them.
  """
  use StarterKit.DataCase, async: true

  import AshOban.Test

  alias StarterKit.Accounts.Token

  defp seed_expired_token do
    Ash.Seed.seed!(Token, %{
      jti: "expired-#{System.unique_integer([:positive])}",
      subject: "user?id=#{Ash.UUID.generate()}",
      expires_at: DateTime.utc_now() |> DateTime.add(-1, :day) |> DateTime.truncate(:second),
      purpose: "user"
    })
  end

  test "an expired token matches the trigger and is expunged when it runs" do
    token = seed_expired_token()

    # It matches the trigger's `where` filter, so the scheduler would enqueue it.
    assert_would_schedule(token, :expunge_expired_tokens)

    # Running the trigger enqueues + performs the destroy job, deleting the token.
    assert %{failure: 0} = schedule_and_run_triggers(Token)
    assert [] = Ash.read!(Token, authorize?: false)
  end

  test "a live token is left alone" do
    live =
      Ash.Seed.seed!(Token, %{
        jti: "live-#{System.unique_integer([:positive])}",
        subject: "user?id=#{Ash.UUID.generate()}",
        expires_at: DateTime.utc_now() |> DateTime.add(1, :day) |> DateTime.truncate(:second),
        purpose: "user"
      })

    refute_would_schedule(live, :expunge_expired_tokens)
    assert %{failure: 0} = schedule_and_run_triggers(Token)
    assert [_] = Ash.read!(Token, authorize?: false)
  end
end

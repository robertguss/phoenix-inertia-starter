defmodule StarterKit.Accounts.ExpireUnconfirmedUsersTest do
  @moduledoc """
  KTD-R3: the `expire_unconfirmed_users` AshOban trigger destroys users left
  unconfirmed past the 7-day window, so a pre-registration email squat (F5)
  self-heals instead of locking the real owner out forever.
  """
  use StarterKit.DataCase, async: true

  import AshOban.Test

  alias StarterKit.Accounts.User

  defp seed_user(attrs) do
    Ash.Seed.seed!(
      User,
      Map.merge(
        %{email: "expire-#{System.unique_integer([:positive])}@example.com"},
        attrs
      )
    )
  end

  test "only stale unconfirmed users are destroyed; confirmed and fresh survive" do
    eight_days_ago = DateTime.utc_now() |> DateTime.add(-8, :day)

    stale = seed_user(%{confirmed_at: nil, inserted_at: eight_days_ago})
    confirmed = seed_user(%{confirmed_at: DateTime.utc_now(), inserted_at: eight_days_ago})
    fresh = seed_user(%{confirmed_at: nil, inserted_at: DateTime.utc_now()})

    # Only the stale, still-unconfirmed user matches the trigger's `where`.
    assert_would_schedule(stale, :expire_unconfirmed_users)
    refute_would_schedule(confirmed, :expire_unconfirmed_users)
    refute_would_schedule(fresh, :expire_unconfirmed_users)

    # Running the trigger enqueues + performs the destroy jobs.
    assert %{failure: 0} = schedule_and_run_triggers(User)

    remaining = Ash.read!(User, authorize?: false) |> Enum.map(& &1.id) |> MapSet.new()
    refute MapSet.member?(remaining, stale.id)
    assert MapSet.member?(remaining, confirmed.id)
    assert MapSet.member?(remaining, fresh.id)
  end
end

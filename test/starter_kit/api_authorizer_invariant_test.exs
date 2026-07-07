defmodule StarterKit.ApiAuthorizerInvariantTest do
  @moduledoc """
  F18 / KTD-R7 template invariant: every resource exposed over JSON:API MUST run
  through `Ash.Policy.Authorizer`. Without an authorizer a resource is world-readable,
  so this guards against a future resource gaining `AshJsonApi.Resource` (and a public
  attribute) while silently skipping authorization.

  Pure introspection over the configured domains — no DB, so it stays `async: true`.
  """
  use ExUnit.Case, async: true

  @json_api AshJsonApi.Resource
  @authorizer Ash.Policy.Authorizer

  # Single source of truth for "exposed over JSON:API but not policy-authorized".
  # The suite runs it over the real resources; the negative test runs it over crafted
  # extension/authorizer lists to prove the same check reports a missing authorizer.
  defp offender?(extensions, authorizers),
    do: @json_api in extensions and @authorizer not in authorizers

  defp offender?(resource),
    do:
      offender?(
        Ash.Resource.Info.extensions(resource),
        Ash.Resource.Info.authorizers(resource)
      )

  defp all_resources do
    :starter_kit
    |> Application.fetch_env!(:ash_domains)
    |> Enum.flat_map(&Ash.Domain.Info.resources/1)
  end

  test "every JSON:API-exposed resource has a policy authorizer" do
    resources = all_resources()

    # Non-vacuous: the User resource (and the demo Note when present) really are
    # exposed today, so the assertion below has something to check.
    assert StarterKit.Accounts.User in resources
    assert @json_api in Ash.Resource.Info.extensions(StarterKit.Accounts.User)

    offenders = Enum.filter(resources, &offender?/1)

    assert offenders == [],
           "JSON:API-exposed resources missing #{inspect(@authorizer)} " <>
             "(they would be world-readable): #{inspect(offenders)}"
  end

  test "the invariant fails for an exposed resource that lacks an authorizer" do
    # Proves the check is not vacuous: the exact predicate the suite uses flags an
    # exposed-but-unauthorized resource, and clears a properly authorized one.
    assert offender?([@json_api], [])
    refute offender?([@json_api], [@authorizer])
    refute offender?([], [])
  end
end

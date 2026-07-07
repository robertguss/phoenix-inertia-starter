defmodule StarterKitWeb.ApiRouter do
  @moduledoc """
  JSON:API router (R13). Serves every AshJsonApi route for the configured domains
  plus the auto-generated OpenAPI spec at `/open_api`. The Phoenix router mounts it
  under `/api/v1`, and the Swagger UI at `/api/v1/docs` reads the spec from here.
  """
  use AshJsonApi.Router,
    domains: [StarterKit.Accounts],
    open_api: "/open_api",
    open_api_title: "StarterKit API",
    open_api_version: "1.0.0"
end

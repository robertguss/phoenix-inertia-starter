defmodule StarterKit.Repo.Migrations.AddObanJobsTable do
  @moduledoc """
  Creates the `oban_jobs` table (and the Postgres notifier triggers) that back
  background jobs (R4). Uses Oban's versioned migrator so future Oban upgrades can
  bump the schema.
  """
  use Ecto.Migration

  def up, do: Oban.Migration.up()

  def down, do: Oban.Migration.down(version: 1)
end

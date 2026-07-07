defmodule StarterKit.Workers.ExampleWorker do
  @moduledoc """
  A minimal plain-Oban worker (R4) — the pattern for background jobs that are not
  tied to an Ash action. Enqueue it with:

      %{"message" => "hello"}
      |> StarterKit.Workers.ExampleWorker.new()
      |> Oban.insert()

  For work that operates on Ash resources, prefer an AshOban trigger or scheduled
  action instead (see the `expunge_expired_tokens` trigger on
  `StarterKit.Accounts.Token`).
  """
  use Oban.Worker, queue: :default, max_attempts: 3

  require Logger

  @impl Oban.Worker
  def perform(%Oban.Job{args: args}) do
    Logger.info("#{inspect(__MODULE__)} ran with args: #{inspect(args)}")
    :ok
  end
end

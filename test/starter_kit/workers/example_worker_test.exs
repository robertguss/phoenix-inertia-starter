defmodule StarterKit.Workers.ExampleWorkerTest do
  use StarterKit.DataCase, async: true
  use Oban.Testing, repo: StarterKit.Repo

  alias StarterKit.Workers.ExampleWorker

  test "enqueues a job and performs it" do
    assert {:ok, _job} = Oban.insert(ExampleWorker.new(%{"message" => "hello"}))

    assert_enqueued(worker: ExampleWorker, args: %{"message" => "hello"})

    assert :ok = perform_job(ExampleWorker, %{"message" => "hello"})
  end
end

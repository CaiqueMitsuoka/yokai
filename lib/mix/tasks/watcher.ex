defmodule Mix.Tasks.Watcher do
  @moduledoc """
  Starts the task to watch files for changes and trigger a check.
  """

  @preferred_cli_env :test

  use Mix.Task

  @impl Mix.Task
  def run(_args) do
    IO.puts("Startging CheckRunner watcher...")
    subscribe()

    IO.inspect(Mix.env())
    file_watcher()
  end

  defp subscribe do
    {:ok, pid} = FileSystem.start_link(dirs: [File.cwd!()])
    FileSystem.subscribe(pid)
  end

  defp file_watcher do
    receive do
      {:file_event, _worker_pid, {file_path, events}} ->
        IO.inspect(file_path, label: :file_path)
        IO.inspect(events, label: :events)
        IO.puts("File event received")
        file_watcher()

      {:file_event, _worker_pid, :stop} ->
        subscribe()
        file_watcher()
    end
  end
end

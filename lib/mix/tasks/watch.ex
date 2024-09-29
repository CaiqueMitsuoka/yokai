defmodule Mix.Tasks.Watch do
  use Mix.Task
  require Logger

  @shortdoc "Watches for file changes and runs tests"

  @impl Mix.Task

  alias Yokai.Options.CLIParser
  alias Yokai.Recompiler
  alias Yokai.Initializer

  def run(args) do
    options =
      args
      |> CLIParser.parse()
      |> Initializer.run()

    load_configs()
    Yokai.Application.start(:app, options)

    {:ok, pid} = FileSystem.start_link(dirs: options.watch_folders)
    FileSystem.subscribe(pid)

    run_tests(options.test_patterns)
    watch_files(options.test_patterns)
  end

  defp watch_files(test_files) do
    receive do
      {:file_event, _watcher_pid, {path, _events}} ->
        Logger.info("File changed: #{path}")
        run_tests(test_files)
        watch_files(test_files)

      {:file_event, _watcher_pid, :stop} ->
        Logger.info("Watcher stopped.")
    end
  end

  defp run_tests(test_files_pattern) do
    with :ok <- Initializer.loadpaths(),
         :ok <- Recompiler.recompile_all(test_files_pattern) do
      Logger.info("Running tests...")

      ExUnit.run()
    else
      _ -> Logger.error("Error running tests.")
    end
  end

  defp load_configs do
    Mix.Task.run("loadconfig")

    Mix.Task.run("app.config")

    Logger.info("Configurations loaded.")
  end
end

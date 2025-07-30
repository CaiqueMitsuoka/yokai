defmodule Mix.Tasks.Watch do
  use Mix.Task
  require Logger

  @shortdoc "Watches for file changes and runs tests"

  @impl Mix.Task

  alias Yokai.ExsRecompiler
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

    Logger.debug("Started with: #{inspect(options)}")

    run_tests(options)
    watch_files(options)
  end

  defp watch_files(opts) do
    receive do
      {:file_event, _watcher_pid, {path, _events}} ->
        Logger.info("File changed: #{path}")
        run_tests(opts)
        watch_files(opts)

      {:file_event, _watcher_pid, :stop} ->
        Logger.info("Watcher stopped.")
    end
  end

  defp run_tests(opts) do
    with :ok <- Initializer.loadpaths(),
         :ok <- Recompiler.recompile_all(opts) do
      Logger.info("Running tests...")

      test_modules =
        opts
        |> Map.get(:test_files_paths)
        |> Enum.map(&ExsRecompiler.find_modules_from_file(&1))
        |> List.flatten()

      Logger.debug("Test modules: #{inspect(test_modules)}")

      ExUnit.run(test_modules)
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

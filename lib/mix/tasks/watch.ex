defmodule Mix.Tasks.Watch do
  use Mix.Task
  require Logger

  @shortdoc "Watches for file changes and runs tests"

  @impl Mix.Task

  alias Yokai.Options.CLIParser
  alias Yokai.Initializer
  alias Yokai.Runner

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

  defp run_tests(opts), do: Runner.start(opts)

  defp load_configs do
    Mix.Task.run("loadconfig")

    Mix.Task.run("app.config")

    Logger.info("Configurations loaded.")
  end
end

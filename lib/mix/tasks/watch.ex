defmodule Mix.Tasks.Watch do
  @moduledoc """
  Watches for file changes and automatically runs tests.

  ## Usage

      mix watch [test_patterns] [options]

  ## Options

    * `--watch-folders` (`-w`) - Comma-separated list of folders to watch for changes (default: "lib,test")
    * `--test-patterns` (`-t`) - Comma-separated list of test patterns to run (default: "test/**/*_test.exs")
    * `--compile-timeout` (`-c`) - Compilation timeout in seconds (default: 30)

  ## Examples

      # Watch default folders and run all tests
      mix watch

      # Watch specific folders
      mix watch --watch-folders lib,test,config

      # Run specific test patterns
      mix watch --test-patterns "test/unit/**/*_test.exs,test/integration/**/*_test.exs"

      # Set custom compile timeout
      mix watch --compile-timeout 60

      # Run specific test files
      mix watch test/my_test.exs test/other_test.exs

      # Combine options
      mix watch test/unit test/integration -w lib,test -c 45
  """

  use Mix.Task
  require Logger

  @shortdoc "Watches for file changes and runs tests"

  @impl Mix.Task

  alias Yokai.Options.CLIParser
  alias Yokai.Initializer
  alias Yokai.Runner
  alias Yokai.TUI

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
    tui_listener = TUI.listen_new_command()

    receive do
      :run ->
        TUI.puts("Triggered by the user")
        Task.shutdown(tui_listener, :brutal_kill)
        run_tests(opts)
        watch_files(opts)

      {:update_options, new_opts} ->
        opts = Map.merge(opts, new_opts)
        TUI.puts("Configurations updated.")
        run_tests(opts)
        watch_files(opts)

      {:file_event, _watcher_pid, {path, _events}} ->
        TUI.puts("File changed: #{path}")
        Task.shutdown(tui_listener, :brutal_kill)
        run_tests(opts)
        watch_files(opts)

      {:file_event, _watcher_pid, :stop} ->
        TUI.puts("Watcher stopped.")

      :quit ->
        IO.puts("Bye bye")
        Process.sleep(100)
        System.halt(0)
    end
  end

  defp run_tests(opts), do: Runner.start(opts)

  defp load_configs do
    Mix.Task.run("loadconfig")

    Mix.Task.run("app.config")

    TUI.puts("Configurations loaded.")
  end
end

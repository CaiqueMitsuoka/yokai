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
  alias Yokai.IOProxy
  alias Yokai.Runner
  alias Yokai.TUI

  def run(args) do
    options =
      args
      |> CLIParser.parse()
      |> Initializer.run()

    load_configs()
    Yokai.Application.start(:app, options)

    IOProxy.set_group_leader()
    ExUnit.start(auto_run: false)
    {:ok, terminal} = TUI.subscribe()
    options = %{options | terminal: terminal}

    {:ok, pid} = FileSystem.start_link(dirs: options.watch_folders)
    FileSystem.subscribe(pid)

    Logger.debug("Started with: #{inspect(options)}")

    run_tests(options)
    watch_files(options)
  end

  defp watch_files(opts) do
    TUI.show_menu()
    ref = opts.terminal.reader

    receive do
      {^ref, {:data, key}} ->
        case TUI.validate_command(String.trim(key), opts) do
          {:ok, :run} ->
            TUI.puts("Triggered by the user")
            run_tests(opts)
            watch_files(opts)

          {:ok, :quit} ->
            IO.puts("Bye bye")
            Process.sleep(100)
            System.halt(0)

          {:ok, {:run_with_opts, new_opts}} ->
            TUI.puts("Configurations updated.")
            run_tests(new_opts)
            watch_files(new_opts)

          {:ok, {:run_once_with_opts, temp_opts}} ->
            TUI.puts("Running once...")
            run_tests(temp_opts)
            watch_files(opts)

          {:error, _} ->
            watch_files(opts)
        end

      {:file_event, _watcher_pid, {path, _events}} ->
        TUI.puts("File changed: #{path}")
        run_tests(opts)
        watch_files(opts)

      {:file_event, _watcher_pid, :stop} ->
        TUI.puts("Watcher stopped.")
    end
  end

  defp run_tests(opts), do: Runner.start(opts)

  defp load_configs do
    Mix.Task.run("loadconfig")

    Mix.Task.run("app.config")

    TUI.puts("Configurations loaded.")
  end
end

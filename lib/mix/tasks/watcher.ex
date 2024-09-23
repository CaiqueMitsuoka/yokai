defmodule Mix.Tasks.CheckRunner do
  use Mix.Task
  require Logger

  @shortdoc "Watches for file changes and runs tests"
  @recursive true

  @impl Mix.Task
  def run(args) do
    {opts, _, _} =
      OptionParser.parse(args,
        switches: [
          directories: :string,
          test_files: :string
        ],
        aliases: [d: :directories, t: :test_files, f: :force]
      )

    directories = Keyword.get(opts, :directories, "lib,test") |> String.split(",")
    test_files = Keyword.get(opts, :test_files, "test/**/*_test.exs") |> String.split(",")

    Mix.shell().info("Starting CheckRunner...")
    Mix.shell().info("Watching directories: #{Enum.join(directories, ", ")}")
    Mix.shell().info("Test files pattern: #{Enum.join(test_files, ", ")}")

    iex_running? = IEx.started?()
    Mix.shell().info("IEx running: #{iex_running?}")

    Application.ensure_all_started(:file_system)
    {:ok, pid} = FileSystem.start_link(dirs: directories)
    FileSystem.subscribe(pid)

    watch_files(test_files)
  end

  defp watch_files(test_files) do
    receive do
      {:file_event, _watcher_pid, {path, _events}} ->
        Mix.shell().info("File changed: #{path}")
        run_tests(test_files)
        watch_files(test_files)

      {:file_event, _watcher_pid, :stop} ->
        Mix.shell().info("Watcher stopped.")
    end
  end

  defp run_tests(test_files_pattern) do
    Mix.shell().info("Recompiling...")
    WarningFilter.filter_warnings()
    recompile()

    # Ensure the test environment is loaded
    Mix.Task.run("loadpaths")
    for {mod, _file} <- Code.required_files(), do: :code.purge(mod)
    for {mod, _file} <- Code.required_files(), do: :code.delete(mod)

    # Require test_helper.exs
    Code.require_file("test/test_helper.exs")

    # Find all test files matching the pattern
    test_files = Path.wildcard(test_files_pattern)

    # Force recompilation of test files
    Enum.each(test_files, &Code.compile_file/1)

    # Run the tests
    ExUnit.start(auto_run: false)

    # Require test helper
    Code.require_file("test/test_helper.exs")

    Enum.each(test_files, fn file ->
      Mix.shell().info("Loading test file: #{file}")
      Code.require_file(file)
    end)

    WarningFilter.restore_warnings()
    Mix.shell().info("Running tests...")

    ExUnit.run()
  end

  defp recompile do
    try do
      IEx.Helpers.recompile()
    rescue
      e in FunctionClauseError ->
        Mix.shell().error("Error during recompilation: #{Exception.message(e)}")
        Mix.shell().info("Falling back to Mix.Task.rerun(\"compile\")")
        Mix.Task.rerun("compile")
    end
  end
end

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

    load_configs()

    Application.ensure_all_started(:file_system)
    {:ok, pid} = FileSystem.start_link(dirs: directories)
    FileSystem.subscribe(pid)

    run_tests(test_files)
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
    recompile()

    # Ensure the test environment is loaded
    Mix.Task.run("loadpaths")
    for {mod, _file} <- Code.required_files(), do: :code.purge(mod)
    for {mod, _file} <- Code.required_files(), do: :code.delete(mod)

    # Start all necessary applications
    start_applications()

    # Reload test_helper.exs
    reload_test_helper()
    # Run the tests
    ExUnit.start(auto_run: false)

    # Find all test files matching the pattern
    test_files = Path.wildcard(test_files_pattern)

    # Force recompilation of test files
    Enum.each(test_files, &Code.compile_file/1)

    Enum.each(test_files, fn file ->
      Mix.shell().info("Loading test file: #{file}")
      Code.require_file(file)
    end)

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

  defp reload_test_helper do
    Mix.shell().info("Reloading test_helper.exs")
    test_helper_path = "test/test_helper.exs"

    if File.exists?(test_helper_path) do
      Code.unrequire_files([test_helper_path])
      Code.require_file(test_helper_path)
    else
      Mix.shell().error("test_helper.exs not found")
    end
  end

  defp start_applications do
    Mix.shell().info("Starting applications...")

    # Get the application name from mix.exs
    app_name = Mix.Project.config()[:app]

    # Start the main application and its dependencies
    {:ok, _} = Application.ensure_all_started(app_name)

    # Explicitly start Mimic
    {:ok, _} = Application.ensure_all_started(:mimic)

    Mix.shell().info("Applications started.")
  end

  defp load_configs do
    Mix.shell().info("Loading configurations...")

    # Load the config for the current Mix env
    Mix.Task.run("loadconfig")

    # Ensure Ecto repos are started with the loaded config
    Mix.Task.run("app.config")

    # If you have any specific configurations to load, do it here
    # For example:
    # Application.put_env(:your_app, :key, value)

    Mix.shell().info("Configurations loaded.")
  end
end

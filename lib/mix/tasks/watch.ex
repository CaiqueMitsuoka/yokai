defmodule Mix.Tasks.Watch do
  use Mix.Task
  require Logger

  @shortdoc "Watches for file changes and runs tests"

  @impl Mix.Task

  alias Yokai.Options.CLIParser

  def run(args) do
    IO.inspect(Mix.env(), label: :env)
    IO.inspect(args, label: :args)

    options = CLIParser.parse(args)

    Logger.info("Starting CheckRunner...")
    Logger.info("Watching directories: #{Enum.join(options.watch_folders, ", ")}")
    Logger.info("Test files pattern: #{Enum.join(options.test_patterns, ", ")}")

    iex_running? = IEx.started?()
    Logger.info("IEx running: #{iex_running?}")

    load_configs()

    Application.ensure_all_started(:file_system)
    {:ok, pid} = FileSystem.start_link(dirs: options.watch_folders)
    FileSystem.subscribe(pid)

    ExUnit.start(auto_run: false)

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
    Logger.info("Recompiling...")
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

    # Find all test files matching the pattern
    test_files = Path.wildcard(test_files_pattern)

    # Force recompilation of test files
    Enum.each(test_files, &Code.compile_file/1)

    Enum.each(test_files, fn file ->
      Logger.info("Loading test file: #{file}")
      Code.require_file(file)
    end)

    Logger.info("Running tests...")

    ExUnit.run()
  end

  defp recompile do
    try do
      IEx.Helpers.recompile()
    rescue
      e in FunctionClauseError ->
        Logger.error("Error during recompilation: #{Exception.message(e)}")
        Logger.info("Falling back to Mix.Task.rerun(\"compile\")")
        Mix.Task.rerun("compile")
    end
  end

  defp reload_test_helper do
    Logger.info("Reloading test_helper.exs")
    test_helper_path = "test/test_helper.exs"

    if File.exists?(test_helper_path) do
      Code.unrequire_files([test_helper_path])
      Code.require_file(test_helper_path)
    else
      Logger.error("test_helper.exs not found")
    end
  end

  defp start_applications do
    Logger.info("Starting applications...")

    # Get the application name from mix.exs
    app_name = Mix.Project.config()[:app]

    # Start the main application and its dependencies
    {:ok, _} = Application.ensure_all_started(app_name)

    Logger.info("Applications started.")
  end

  defp load_configs do
    Logger.info("Loading configurations...")

    # Load the config for the current Mix env
    Mix.Task.run("loadconfig")

    # Ensure Ecto repos are started with the loaded config
    Mix.Task.run("app.config")

    # If you have any specific configurations to load, do it here
    # For example:
    # Application.put_env(:your_app, :key, value)

    Logger.info("Configurations loaded.")
  end
end

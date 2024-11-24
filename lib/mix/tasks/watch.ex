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
    Yokai.Application.start(:app, options)
    Process.sleep(1000)

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
    with :ok <- recompile_code(),
         :ok <- loadpaths(),
         :ok <- start_applications(),
         :ok <- GenServer.call(Yokai.Recompiler, {:tests, test_files_pattern}) do
      Logger.info("Running tests...")

      ExUnit.run()
    else
      _ -> Logger.error("Error running tests.")
    end
  end

  def recompile_code() do
    Logger.info("Recompiling...")

    case GenServer.call(Yokai.Recompiler, :code) do
      :noop -> :ok
      :ok -> :ok
      _ -> :error
    end
  end

  def loadpaths() do
    case Mix.Task.run("loadpaths") do
      :noop -> :ok
      :ok -> :ok
      _ -> :error
    end
  end

  defp start_applications do
    Logger.info("Starting applications...")

    # Get the application name from mix.exs
    app_name = Mix.Project.config()[:app]

    # Start the main application and its dependencies
    {:ok, _} = Application.ensure_all_started(app_name)

    Logger.info("Applications started.")
    :ok
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

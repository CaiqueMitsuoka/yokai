defmodule Yokai.Recompiler do
  @moduledoc """
  Recompiles the project
  """

  use GenServer
  require Logger

  def start_link do
    GenServer.start_link(__MODULE__, %{}, name: __MODULE__)
  end

  def child_spec(_) do
    %{
      id: __MODULE__,
      start: {__MODULE__, :start_link, []}
    }
  end

  @impl true
  def init(_) do
    {:ok, %{}}
  end

  @impl true
  def handle_call(:code, _caller, state) do
    {:reply, compile_code(), state}
  end

  @impl true
  def handle_call({:tests, pattern}, _caller, state) do
    {:reply, compile_tests(pattern), state}
  end

  defp compile_code do
    try do
      IEx.Helpers.recompile()
    rescue
      e in FunctionClauseError ->
        Logger.error("Error during recompilation: #{Exception.message(e)}")
        Logger.info("Falling back to Mix.Task.rerun(\"compile\")")
        Mix.Task.rerun("compile")
    end
  end

  defp compile_tests(test_files_pattern) do
    with :ok <- purge_test_modules(),
         test_files <- Path.wildcard(test_files_pattern),
         :ok <- compile_test_files(test_files),
         :ok <- reload_test_helper(),
         :ok <- load_test_files(test_files) do
      :ok
    else
      _ -> :error
    end
  end

  def purge_test_modules do
    for {mod, _file} <- Code.required_files(), do: :code.purge(mod)
    for {mod, _file} <- Code.required_files(), do: :code.delete(mod)
    :ok
  end

  def compile_test_files(test_files) do
    try do
      Enum.each(test_files, &Code.compile_file/1)
      :ok
    rescue
      e in CompileError ->
        Logger.error("Error during test compilation: #{Exception.message(e)}")
        :error
    end
  end

  def load_test_files(test_files) do
    try do
      Enum.each(test_files, fn file ->
        Logger.info("Loading test file: #{file}")
        Code.require_file(file)
      end)

      :ok
    rescue
      e in CompileError ->
        Logger.error("Error during test loading: #{Exception.message(e)}")
        :error
    end
  end

  defp reload_test_helper do
    Logger.info("Reloading test_helper.exs")
    test_helper_path = "test/test_helper.exs"

    if File.exists?(test_helper_path) do
      Code.unrequire_files([test_helper_path])
      Code.require_file(test_helper_path)
      :ok
    else
      Logger.error("test_helper.exs not found")
      :error
    end
  end
end

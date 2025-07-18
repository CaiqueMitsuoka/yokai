defmodule Yokai.ExsRecompiler do
  require Logger

  def from_pattern(test_files_pattern) do
    with test_files <- Path.wildcard(test_files_pattern),
         :ok <- purge_test_modules(test_files),
         :ok <- compile_test_files(test_files),
         :ok <- reload_test_helper() do
      :ok
    else
      _ -> :error
    end
  end

  defp purge_test_modules(test_paths) do
    Enum.each(test_paths, &reload_test_file/1)

    :ok
  end

  defp reload_test_file(file_path) do
    modules_from_file = find_modules_from_file(file_path)

    Enum.each(modules_from_file, fn module ->
      :code.purge(module)
      :code.delete(module)
    end)
  end

  defp find_modules_from_file(file_path) do
    absolute_path = Path.expand(file_path)

    :code.all_loaded()
    |> Enum.map(&elem(&1, 0))
    |> Enum.filter(fn module ->
      case get_source_file(module) do
        ^absolute_path -> true
        _ -> false
      end
    end)
  end

  defp get_source_file(module) do
    try do
      module.__info__(:compile)[:source] |> to_string() |> Path.expand()
    rescue
      _ -> nil
    end
  end

  defp compile_test_files(test_files) do
    try do
      Enum.each(test_files, &Code.compile_file/1)
      :ok
    rescue
      e in CompileError ->
        Logger.error("Error during test compilation: #{Exception.message(e)}")
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

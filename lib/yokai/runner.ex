defmodule Yokai.Runner do
  require Logger

  alias Yokai.Recompiler
  alias Yokai.ExsRecompiler
  alias Yokai.Initializer

  def start(opts) do
    with :ok <- Initializer.loadpaths(),
         :ok <- Recompiler.recompile_all(opts) do
      test_modules = extract_test_modules(opts)
      reset_seed()
      Logger.debug("Test modules: #{inspect(test_modules)}")

      Logger.info("Running tests...")
      ExUnit.run(test_modules)
    else
      _ -> Logger.error("Error running tests.")
    end
  end

  def extract_test_modules(opts) do
    opts
    |> Map.get(:test_files_paths)
    |> Enum.map(&ExsRecompiler.find_modules_from_file(&1))
    |> List.flatten()
  end

  def reset_seed, do: Application.delete_env(:ex_unit, :seed)
end

defmodule Yokai.RunnerTest do
  use ExUnit.Case, async: false
  alias Yokai.Runner
  alias Yokai.Options

  describe "extract_test_modules/1" do
    test "calls ExsRecompiler.find_modules_from_file for each file path" do
      opts = %Options{
        test_files_paths: ["test/sample_module_test.exs"]
      }

      result = Runner.extract_test_modules(opts)
      assert [Yokai.SampleModuleTest]
    end

    test "handles empty test files paths" do
      opts = %Options{test_files_paths: []}

      result = Runner.extract_test_modules(opts)
      assert result == []
    end

    test "flattens results from multiple files" do
      opts = %Options{
        test_files_paths: ["test/sample_module_test.exs", "test/yokai/runner_test.exs"]
      }

      result = Runner.extract_test_modules(opts)
      assert [Yokai.SampleModuleTest, __MODULE__]
    end
  end

  describe "reset_seed/0" do
    test "deletes the ex_unit seed from application environment" do
      Application.put_env(:ex_unit, :seed, 12345)
      assert Application.get_env(:ex_unit, :seed) == 12345

      Runner.reset_seed()

      assert Application.get_env(:ex_unit, :seed) == nil
    end

    test "handles case when seed is not set" do
      Application.delete_env(:ex_unit, :seed)

      assert Runner.reset_seed() == :ok
    end
  end
end

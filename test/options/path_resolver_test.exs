defmodule Yokai.Options.PathResolverTest do
  use ExUnit.Case, async: true
  alias Yokai.Options.PathResolver

  describe "resolve/1" do
    test "resolves glob patterns to .exs files" do
      result = PathResolver.resolve(["test/*.exs"])

      assert is_list(result)
      assert Enum.all?(result, &String.ends_with?(&1, ".exs"))
      assert "test/sample_module_test.exs" in result
      assert "test/yokai_test.exs" in result
    end

    test "resolves specific file paths" do
      result = PathResolver.resolve(["test/sample_module_test.exs"])

      assert result == ["test/sample_module_test.exs"]
    end

    test "resolves directory paths recursively" do
      result = PathResolver.resolve(["test/options"])

      assert is_list(result)
      assert Enum.all?(result, &String.ends_with?(&1, ".exs"))
      assert "test/options/cli_parser_test.exs" in result
    end

    test "handles mixed patterns and paths" do
      result = PathResolver.resolve(["test/*.exs", "test/options"])

      assert is_list(result)
      assert Enum.all?(result, &String.ends_with?(&1, ".exs"))
      assert "test/sample_module_test.exs" in result
      assert "test/options/cli_parser_test.exs" in result
    end

    test "removes duplicates and sorts results" do
      result = PathResolver.resolve(["test/sample_module_test.exs", "test/*.exs"])

      assert result == Enum.sort(Enum.uniq(result))
      assert Enum.count(result, &(&1 == "test/sample_module_test.exs")) == 1
    end

    test "returns empty list for non-existent patterns" do
      result = PathResolver.resolve(["non_existent/*"])

      assert result == []
    end

    test "returns empty list for non-existent files" do
      result = PathResolver.resolve(["non_existent_file.exs"])

      assert result == []
    end

    test "filters out non-.exs files" do
      # This test assumes there might be non-.exs files in the directory
      result = PathResolver.resolve(["test/*"])

      assert Enum.all?(result, &String.ends_with?(&1, ".exs"))
    end

    test "handles empty input list" do
      result = PathResolver.resolve([])

      assert result == []
    end

    test "handles nested glob patterns" do
      result = PathResolver.resolve(["test/**/*.exs"])

      assert is_list(result)
      assert Enum.all?(result, &String.ends_with?(&1, ".exs"))
      assert "test/sample_module_test.exs" in result
      assert "test/options/cli_parser_test.exs" in result
    end
  end
end

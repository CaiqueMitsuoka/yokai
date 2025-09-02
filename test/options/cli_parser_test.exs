defmodule Yokai.Options.CLIParserTest do
  use ExUnit.Case
  doctest Yokai.Options.CLIParser
  alias Yokai.Options.CLIParser
  alias Yokai.Options

  describe "parse/1" do
    test "returns the default values when no arguments are passed" do
      assert CLIParser.parse([]) == %Options{
               watch_folders: ["lib", "test"],
               test_patterns: ["test/**/*_test.exs"],
               test_files_paths: [
                 "test/options/cli_parser_test.exs",
                 "test/options/path_resolver_test.exs",
                 "test/sample_module_test.exs",
                 "test/yokai/runner_test.exs",
                 "test/yokai/tui_test.exs",
                 "test/yokai_test.exs"
               ]
             }
    end

    test "parses the watch_folders argument" do
      assert CLIParser.parse(["-w", "foo,bar"]) == %Options{
               watch_folders: ["foo", "bar"],
               test_patterns: ["test/**/*_test.exs"],
               test_files_paths: [
                 "test/options/cli_parser_test.exs",
                 "test/options/path_resolver_test.exs",
                 "test/sample_module_test.exs",
                 "test/yokai/runner_test.exs",
                 "test/yokai/tui_test.exs",
                 "test/yokai_test.exs"
               ]
             }
    end

    test "parses the test_patterns argument" do
      assert CLIParser.parse(["-t", "test/application_test.ex"]) == %Options{
               watch_folders: ["lib", "test"],
               test_patterns: ["test/application_test.ex"]
             }
    end

    test "parses the watch_folders and test_patterns arguments" do
      assert CLIParser.parse(["-w", "foo,bar", "-t", "test/application_test.ex"]) == %Options{
               watch_folders: ["foo", "bar"],
               test_patterns: ["test/application_test.ex"]
             }
    end

    test "uses default test pattern only when no patterns or files provided" do
      result = CLIParser.parse([])
      assert result.test_patterns == ["test/**/*_test.exs"]
    end

    test "does not use default when test_patterns option is provided" do
      result = CLIParser.parse(["-t", "test/specific_test.exs"])
      assert result.test_patterns == ["test/specific_test.exs"]
    end

    test "does not use default when file arguments are provided" do
      result = CLIParser.parse(["test/sample_module_test.exs"])
      assert result.test_patterns == ["test/sample_module_test.exs"]
    end

    test "combines test_patterns option with file arguments" do
      result = CLIParser.parse(["-t", "test/pattern_test.exs", "test/file_test.exs"])
      assert result.test_patterns == ["test/pattern_test.exs", "test/file_test.exs"]
    end

    test "handles comma-separated test_patterns" do
      result = CLIParser.parse(["-t", "test/first.exs,test/second.exs"])
      assert result.test_patterns == ["test/first.exs", "test/second.exs"]
    end

    test "combines comma-separated patterns with file arguments" do
      result = CLIParser.parse(["-t", "test/first.exs,test/second.exs", "test/third.exs"])
      assert result.test_patterns == ["test/first.exs", "test/second.exs", "test/third.exs"]
    end

    test "resolves test file paths using PathResolver" do
      result = CLIParser.parse(["-t", "test/sample_module_test.exs"])
      assert result.test_files_paths == ["test/sample_module_test.exs"]
    end

    test "includes compile_timeout option" do
      result = CLIParser.parse(["-c", "60"])
      assert result.compile_timeout == 60_000
    end

    test "test_patterns_to_map returns correct map with test patterns and resolved paths" do
      test_patterns = ["test/sample_module_test.exs"]
      result = CLIParser.test_patterns_to_map(test_patterns)

      assert result == %{
               test_patterns: ["test/sample_module_test.exs"],
               test_files_paths: ["test/sample_module_test.exs"]
             }
    end

    test "test_patterns_to_map handles multiple patterns" do
      test_patterns = ["test/sample_module_test.exs", "test/yokai_test.exs"]
      result = CLIParser.test_patterns_to_map(test_patterns)

      assert result == %{
               test_patterns: ["test/sample_module_test.exs", "test/yokai_test.exs"],
               test_files_paths: ["test/sample_module_test.exs", "test/yokai_test.exs"]
             }
    end
  end

  describe "default_test_pattern/0" do
    test "returns default test pattern" do
      assert CLIParser.default_test_pattern() == ["test/**/*_test.exs"]
    end
  end
end

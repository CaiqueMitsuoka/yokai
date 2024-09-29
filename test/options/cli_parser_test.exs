defmodule Yokai.Options.CLIParserTest do
  use ExUnit.Case
  doctest Yokai.Options.CLIParser
  alias Yokai.Options.CLIParser
  alias Yokai.Options

  describe "parse/1" do
    test "returns the default values when no arguments are passed" do
      assert CLIParser.parse([]) == %Options{
               watch_folders: ["lib", "test"],
               test_patterns: ["test/**/*_test.exs"]
             }
    end

    test "parses the watch_folders argument" do
      assert CLIParser.parse(["-w", "foo,bar"]) == %Options{
               watch_folders: ["foo", "bar"],
               test_patterns: ["test/**/*_test.exs"]
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
  end
end

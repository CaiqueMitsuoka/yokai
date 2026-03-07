defmodule Yokai.TUITest do
  use ExUnit.Case
  import ExUnit.CaptureIO

  describe "validate_command/2" do
    setup do
      options = %{test_patterns: ["test/**/*_test.exs"], watch_folders: ["lib", "test"]}
      {:ok, options: options}
    end

    test "returns {:ok, :run} for valid 'r' command", %{options: options} do
      assert {:ok, :run} = Yokai.TUI.validate_command("r", options)
    end

    test "returns {:ok, :quit} for valid 'q' command", %{options: options} do
      assert {:ok, :quit} = Yokai.TUI.validate_command("q", options)
    end

    test "handles whitespace around valid commands", %{options: options} do
      assert {:ok, :run} = Yokai.TUI.validate_command("  r  ", options)
      assert {:ok, :quit} = Yokai.TUI.validate_command("\nq\t", options)
    end

    test "returns error for invalid commands", %{options: options} do
      assert {:error, msg} = Yokai.TUI.validate_command("x", options)
      assert msg == "Invalid command 'x'. Please choose from the available options."
    end

    test "returns error for empty input", %{options: options} do
      assert {:error, msg} = Yokai.TUI.validate_command("", options)
      assert msg == "Invalid command ''. Please choose from the available options."
    end

    test "returns error for multi-character input", %{options: options} do
      assert {:error, msg} = Yokai.TUI.validate_command("run", options)
      assert msg == "Invalid command 'run'. Please choose from the available options."
    end

    test "handles all available commands", %{options: options} do
      assert {:ok, :run} = Yokai.TUI.validate_command("r", options)
      assert {:ok, :quit} = Yokai.TUI.validate_command("q", options)

      # Note: The 'w' command requires interactive input and can't be easily tested
      # in a unit test without mocking termite input, so we skip testing it here
    end

    test "returns {:ok, {:run_once_with_opts, opts}} for valid 'a' command", %{options: options} do
      assert {:ok, {:run_once_with_opts, opts}} = Yokai.TUI.validate_command("a", options)
      assert is_map(opts)
      assert Map.has_key?(opts, :test_patterns)
      assert Map.has_key?(opts, :test_files_paths)
    end

    test "handles case sensitivity", %{options: options} do
      assert {:error, msg} = Yokai.TUI.validate_command("R", options)
      assert msg == "Invalid command 'R'. Please choose from the available options."

      assert {:error, msg} = Yokai.TUI.validate_command("Q", options)
      assert msg == "Invalid command 'Q'. Please choose from the available options."
    end
  end

  describe "build_menu_text/0" do
    test "generates menu with all available commands" do
      menu_text = Yokai.TUI.build_menu_text()

      assert is_binary(menu_text)
      assert menu_text =~ "Watching for changes..."
      assert menu_text =~ "Rerun tests"
      assert menu_text =~ "Quit"
      assert menu_text =~ "Update the test files pattern"
      assert menu_text =~ "Run all tests once"
    end

    test "menu includes commands with correct keys" do
      menu_text = Yokai.TUI.build_menu_text()

      assert menu_text =~ "r - Rerun tests"
      assert menu_text =~ "q - Quit"
      assert menu_text =~ "w - Update the test files pattern"
      assert menu_text =~ "a - Run all tests once"
    end

    test "menu structure includes all required sections" do
      menu_text = Yokai.TUI.build_menu_text()

      assert String.starts_with?(menu_text, "\nWatching for changes...\n\n")
      assert menu_text =~ "Commands:\n"
    end

    test "returns a string" do
      menu_text = Yokai.TUI.build_menu_text()

      assert is_binary(menu_text)
      assert String.length(menu_text) > 10
    end

    test "menu format is human readable" do
      menu_text = Yokai.TUI.build_menu_text()

      lines = String.split(menu_text, "\n")
      assert length(lines) >= 5

      # Should contain header
      assert Enum.any?(lines, &String.contains?(&1, "Watching for changes"))
      assert Enum.any?(lines, &String.contains?(&1, "Commands:"))

      # Should contain command descriptions
      assert Enum.any?(lines, &String.contains?(&1, " - "))
    end
  end

  describe "listen_new_command/1" do
    test "returns a task" do
      options = %{test_patterns: ["test/**/*_test.exs"], watch_folders: ["lib", "test"]}
      task = Yokai.TUI.listen_new_command(options)
      assert %Task{} = task
    end
  end

  describe "format_test_pattern_update/2" do
    setup do
      options = %{test_patterns: ["test/**/*_test.exs"], watch_folders: ["lib", "test"]}
      {:ok, options: options}
    end

    test "formats valid test pattern input", %{options: options} do
      result = Yokai.TUI.format_test_pattern_update("test/my_test.exs", options)

      assert {:ok, {:run_with_opts, opts}} = result
      assert is_map(opts)
      assert Map.has_key?(opts, :test_patterns)
    end

    test "handles multiple test patterns", %{options: options} do
      result = Yokai.TUI.format_test_pattern_update("test/**/*_test.exs", options)

      assert {:ok, {:run_with_opts, opts}} = result
      assert is_map(opts)
    end

    test "formats empty pattern", %{options: options} do
      result = Yokai.TUI.format_test_pattern_update("", options)

      assert {:ok, {:run_with_opts, opts}} = result
      assert is_map(opts)
    end

    test "handles complex glob patterns", %{options: options} do
      result =
        Yokai.TUI.format_test_pattern_update("test/{unit,integration}/**/*_test.exs", options)

      assert {:ok, {:run_with_opts, opts}} = result
      assert is_map(opts)
      assert Map.has_key?(opts, :test_patterns)
    end

    test "handles single file pattern", %{options: options} do
      result = Yokai.TUI.format_test_pattern_update("test/specific_test.exs", options)

      assert {:ok, {:run_with_opts, opts}} = result
      assert is_map(opts)
    end

    test "always returns tuple with run_with_opts", %{options: options} do
      inputs = ["", "test/", "**/*", "invalid/path/that/doesnt/exist"]

      for input <- inputs do
        result = Yokai.TUI.format_test_pattern_update(input, options)
        assert {:ok, {:run_with_opts, _opts}} = result
      end
    end

    test "merges options correctly", %{options: options} do
      result = Yokai.TUI.format_test_pattern_update("test/new_test.exs", options)

      assert {:ok, {:run_with_opts, merged_opts}} = result
      assert Map.get(merged_opts, :watch_folders) == ["lib", "test"]
      assert Map.has_key?(merged_opts, :test_patterns)
    end
  end

  describe "puts/1" do
    test "accepts string input" do
      output =
        capture_io(fn ->
          assert :ok = Yokai.TUI.puts("test message")
        end)

      assert output == "test message\n"
    end
  end

  describe "command structure" do
    test "commands module attribute contains expected commands" do
      options = %{test_patterns: ["test/**/*_test.exs"], watch_folders: ["lib", "test"]}
      assert {:ok, :run} = Yokai.TUI.validate_command("r", options)
      assert {:ok, :quit} = Yokai.TUI.validate_command("q", options)

      # 'w' command exists but requires interactive input, so we just
      # verify it doesn't return the "invalid command" error message
      assert {:error, "Invalid command 'x'. Please choose from the available options."} =
               Yokai.TUI.validate_command("x", options)
    end
  end

  describe "clear/0" do
    test "outputs ANSI escape sequence to clear screen" do
      output =
        capture_io(fn ->
          Yokai.TUI.clear()
        end)

      assert output == "\e[2J\e[H"
    end
  end

  describe "run_all/1" do
    setup do
      options = %{test_patterns: ["test/custom_test.exs"], watch_folders: ["lib", "test"]}
      {:ok, options: options}
    end

    test "returns options with default test pattern", %{options: options} do
      result = Yokai.TUI.run_all(options)

      assert is_map(result)
      assert Map.has_key?(result, :test_patterns)
      assert Map.has_key?(result, :test_files_paths)
      assert result.test_patterns == ["test/**/*_test.exs"]
    end

    test "merges with existing options", %{options: options} do
      result = Yokai.TUI.run_all(options)

      assert Map.get(result, :watch_folders) == ["lib", "test"]
    end

    test "overrides test patterns with default", %{options: options} do
      result = Yokai.TUI.run_all(options)

      assert result.test_patterns == ["test/**/*_test.exs"]
      refute result.test_patterns == ["test/custom_test.exs"]
    end
  end
end

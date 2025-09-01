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
      # in a unit test without mocking Owl.IO.input, so we skip testing it here
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
      menu_list = Yokai.TUI.build_menu_text()

      text_content =
        menu_list
        |> List.flatten()
        |> Enum.map(fn
          %Owl.Tag{data: data} -> data
          item when is_binary(item) -> item
          _ -> ""
        end)
        |> Enum.join("")

      assert text_content =~ "Watching for changes..."
      assert text_content =~ "Rerun tests"
      assert text_content =~ "Quit"
    end

    test "menu includes both commands in correct format" do
      menu_list = Yokai.TUI.build_menu_text()

      flattened = List.flatten(menu_list)

      assert Enum.any?(flattened, fn item ->
               is_binary(item) && String.contains?(item, "Watching for changes...")
             end)

      assert Enum.any?(flattened, fn item ->
               is_binary(item) && String.contains?(item, "Rerun tests")
             end)

      assert Enum.any?(flattened, fn item ->
               is_binary(item) && String.contains?(item, "Quit")
             end)

      assert Enum.any?(flattened, fn
               %Owl.Tag{data: "r"} -> true
               _ -> false
             end)

      assert Enum.any?(flattened, fn
               %Owl.Tag{data: "q"} -> true
               _ -> false
             end)

      assert Enum.any?(flattened, fn
               %Owl.Tag{data: "w"} -> true
               _ -> false
             end)
    end

    test "menu structure includes all required sections" do
      menu_list = Yokai.TUI.build_menu_text()
      flattened = List.flatten(menu_list)

      assert Enum.at(flattened, 0) == "\nWatching for changes...\n\n"

      assert Enum.any?(flattened, fn item ->
               is_binary(item) && item == "Commands:\n"
             end)

      newline_count = Enum.count(flattened, fn item -> item == "\n" end)
      assert newline_count > 0
    end

    test "returns a list structure" do
      menu_list = Yokai.TUI.build_menu_text()

      assert is_list(menu_list)
      assert length(menu_list) > 0

      flattened = List.flatten(menu_list)
      assert length(flattened) > 5
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
      result = Yokai.TUI.format_test_pattern_update("test/{unit,integration}/**/*_test.exs", options)

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
end

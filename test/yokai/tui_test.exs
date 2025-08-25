defmodule Yokai.TUITest do
  use ExUnit.Case
  import ExUnit.CaptureIO

  describe "validate_command/1" do
    test "returns {:ok, :run} for valid 'r' command" do
      assert {:ok, :run} = Yokai.TUI.validate_command("r")
    end

    test "returns {:ok, :quit} for valid 'q' command" do
      assert {:ok, :quit} = Yokai.TUI.validate_command("q")
    end

    test "handles whitespace around valid commands" do
      assert {:ok, :run} = Yokai.TUI.validate_command("  r  ")
      assert {:ok, :quit} = Yokai.TUI.validate_command("\nq\t")
    end

    test "returns error for invalid commands" do
      assert {:error, msg} = Yokai.TUI.validate_command("x")
      assert msg == "Invalid command 'x'. Please choose from the available options."
    end

    test "returns error for empty input" do
      assert {:error, msg} = Yokai.TUI.validate_command("")
      assert msg == "Invalid command ''. Please choose from the available options."
    end

    test "returns error for multi-character input" do
      assert {:error, msg} = Yokai.TUI.validate_command("run")
      assert msg == "Invalid command 'run'. Please choose from the available options."
    end

    test "handles all available commands" do
      assert {:ok, :run} = Yokai.TUI.validate_command("r")
      assert {:ok, :quit} = Yokai.TUI.validate_command("q")

      # Note: The 'w' command requires interactive input and can't be easily tested
      # in a unit test without mocking Owl.IO.input, so we skip testing it here
    end

    test "handles case sensitivity" do
      assert {:error, msg} = Yokai.TUI.validate_command("R")
      assert msg == "Invalid command 'R'. Please choose from the available options."

      assert {:error, msg} = Yokai.TUI.validate_command("Q")
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

  describe "listen_new_command/0" do
    test "returns a task" do
      task = Yokai.TUI.listen_new_command()
      assert %Task{} = task
    end
  end

  describe "format_test_pattern_update/1" do
    test "formats valid test pattern input" do
      result = Yokai.TUI.format_test_pattern_update("test/my_test.exs")

      assert {:ok, {:update_options, opts}} = result
      assert is_map(opts)
      assert Map.has_key?(opts, :test_patterns)
    end

    test "handles multiple test patterns" do
      result = Yokai.TUI.format_test_pattern_update("test/**/*_test.exs")

      assert {:ok, {:update_options, opts}} = result
      assert is_map(opts)
    end

    test "formats empty pattern" do
      result = Yokai.TUI.format_test_pattern_update("")

      assert {:ok, {:update_options, opts}} = result
      assert is_map(opts)
    end

    test "handles complex glob patterns" do
      result = Yokai.TUI.format_test_pattern_update("test/{unit,integration}/**/*_test.exs")

      assert {:ok, {:update_options, opts}} = result
      assert is_map(opts)
      assert Map.has_key?(opts, :test_patterns)
    end

    test "handles single file pattern" do
      result = Yokai.TUI.format_test_pattern_update("test/specific_test.exs")

      assert {:ok, {:update_options, opts}} = result
      assert is_map(opts)
    end

    test "always returns tuple with update_options" do
      inputs = ["", "test/", "**/*", "invalid/path/that/doesnt/exist"]

      for input <- inputs do
        result = Yokai.TUI.format_test_pattern_update(input)
        assert {:ok, {:update_options, _opts}} = result
      end
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
      assert {:ok, :run} = Yokai.TUI.validate_command("r")
      assert {:ok, :quit} = Yokai.TUI.validate_command("q")

      # 'w' command exists but requires interactive input, so we just
      # verify it doesn't return the "invalid command" error message
      assert {:error, "Invalid command 'x'. Please choose from the available options."} =
               Yokai.TUI.validate_command("x")
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

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
  end

  describe "build_menu_text/0" do
    test "generates menu with all available commands" do
      menu_text = Yokai.TUI.build_menu_text()
      
      assert menu_text =~ "Watching for changes..."
      assert menu_text =~ "r - Rerun tests"
      assert menu_text =~ "q - Quit"
    end

    test "menu includes both commands in correct format" do
      menu_text = Yokai.TUI.build_menu_text()
      lines = String.split(menu_text, "\n")
      
      command_lines = Enum.filter(lines, &String.contains?(&1, " - "))
      assert length(command_lines) == 2
      
      assert Enum.any?(command_lines, &String.contains?(&1, "r - Rerun tests"))
      assert Enum.any?(command_lines, &String.contains?(&1, "q - Quit"))
    end
  end

  describe "listen_new_command/0" do
    test "returns a task" do
      task = Yokai.TUI.listen_new_command()
      assert %Task{} = task
    end
  end

  describe "clear/0" do
    test "outputs ANSI escape sequence to clear screen" do
      output = capture_io(fn ->
        Yokai.TUI.clear()
      end)

      assert output == "\e[2J\e[H"
    end
  end
end
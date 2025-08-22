defmodule Yokai.TUITest do
  use ExUnit.Case
  import ExUnit.CaptureIO

  describe "clear/0" do
    test "outputs ANSI escape sequence to clear screen" do
      output = capture_io(fn ->
        Yokai.TUI.clear()
      end)

      assert output == "\e[2J\e[H"
    end
  end
end
defmodule Yokai.TUI do
  def clear do
    IO.write("\e[2J\e[H")
  end
end

defmodule YokaiTest do
  use ExUnit.Case
  doctest Yokai

  test "greets the world" do
    assert Yokai.hello() == :world
  end
end

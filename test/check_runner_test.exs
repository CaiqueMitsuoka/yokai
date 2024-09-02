defmodule CheckRunnerTest do
  use ExUnit.Case
  doctest CheckRunner

  test "greets the world" do
    assert CheckRunner.hello() == :world
  end
end

defmodule SampleModuleTest do
  use ExUnit.Case
  doctest SampleModule
  alias SampleModule

  describe "sum/2" do
    test "adds two numbers" do
      assert SampleModule.sum(1, 1) == 2
    end

    test "adds two odd numbers" do
      assert SampleModule.sum(3, 3) == 6
    end
  end

  describe "sub/2" do
    test "subtracts two numbers" do
      assert SampleModule.sub(1, 1) == 0
    end

    test "subtracts negative numbers" do
      assert SampleModule.sub(3, -3) == 6
    end
  end
end

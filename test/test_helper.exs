ExUnit.start()

defmodule Yokai.IOProxyTest.Helpers.FakeFormatter do
  def format(_event, _config), do: "fake\noutput\n"
end

defmodule Yokai.IOProxyTest.Helpers.CRLFFormatter do
  def format(_event, _config), do: "already\r\ncorrect\r\n"
end

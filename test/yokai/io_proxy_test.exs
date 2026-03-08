defmodule Yokai.IOProxyTest do
  use ExUnit.Case, async: true

  describe "LoggerFormatter" do
    test "translates newlines in formatted output" do
      fake_formatter = {Yokai.IOProxyTest.Helpers.FakeFormatter, :unused}
      result = Yokai.IOProxy.LoggerFormatter.format(%{msg: "test"}, fake_formatter)
      assert result == "fake\r\noutput\r\n"
    end

    test "is idempotent with existing \\r\\n" do
      fake_formatter = {Yokai.IOProxyTest.Helpers.CRLFFormatter, :unused}
      result = Yokai.IOProxy.LoggerFormatter.format(%{msg: "test"}, fake_formatter)
      assert result == "already\r\ncorrect\r\n"
    end
  end
end

defmodule Yokai.IOProxySyncTest do
  use ExUnit.Case

  setup do
    on_exit(&restore_logger_formatter/0)
    :ok
  end

  describe "start_link/1" do
    test "starts as a GenServer" do
      {:ok, pid} = GenServer.start_link(Yokai.IOProxy, :ok)
      assert Process.alive?(pid)
      GenServer.stop(pid)
    end

    test "wraps the logger formatter" do
      {:ok, %{formatter: {orig_mod, _}}} = :logger.get_handler_config(:default)

      {:ok, pid} = GenServer.start_link(Yokai.IOProxy, :ok)

      {:ok, %{formatter: {new_mod, {wrapped_mod, _}}}} = :logger.get_handler_config(:default)
      assert new_mod == Yokai.IOProxy.LoggerFormatter
      assert wrapped_mod == orig_mod

      GenServer.stop(pid)
    end
  end

  describe "set_group_leader/0" do
    test "sets the IOProxy process as the caller's group leader" do
      original_gl = Process.group_leader()

      unless Process.whereis(Yokai.IOProxy), do: start_supervised!(Yokai.IOProxy)

      pid = Process.whereis(Yokai.IOProxy)
      Yokai.IOProxy.set_group_leader()
      assert Process.group_leader() == pid

      Process.group_leader(self(), original_gl)
    end
  end

  describe "newline translation" do
    test "translates \\n to \\r\\n in put_chars" do
      assert_proxy_translates(
        {:put_chars, :unicode, "hello\nworld\n"},
        "hello\r\nworld\r\n"
      )
    end

    test "is idempotent - does not double-translate \\r\\n" do
      assert_proxy_translates(
        {:put_chars, :unicode, "hello\r\nworld\r\n"},
        "hello\r\nworld\r\n"
      )
    end

    test "handles mixed line endings" do
      assert_proxy_translates(
        {:put_chars, :unicode, "line1\r\nline2\nline3\r\n"},
        "line1\r\nline2\r\nline3\r\n"
      )
    end

    test "handles text with no newlines" do
      assert_proxy_translates(
        {:put_chars, :unicode, "no newlines here"},
        "no newlines here"
      )
    end

    test "handles empty string" do
      assert_proxy_translates(
        {:put_chars, :unicode, ""},
        ""
      )
    end

    test "handles charlists" do
      assert_proxy_translates(
        {:put_chars, :unicode, ~c"hello\nworld"},
        "hello\r\nworld"
      )
    end

    test "handles MFA form by eagerly evaluating" do
      assert_proxy_translates(
        {:put_chars, :unicode, IO, :chardata_to_string, [["hello", ?\n, "world"]]},
        "hello\r\nworld"
      )
    end

    test "handles batched requests" do
      request =
        {:requests,
         [
           {:put_chars, :unicode, "first\n"},
           {:put_chars, :unicode, "second\n"}
         ]}

      {_reply, forwarded} = send_through_proxy(request)

      assert {:requests, sub_requests} = forwarded
      assert [{:put_chars, :unicode, first}, {:put_chars, :unicode, second}] = sub_requests
      assert IO.chardata_to_string(first) == "first\r\n"
      assert IO.chardata_to_string(second) == "second\r\n"
    end

    test "forwards non-output requests unchanged" do
      {_reply, forwarded} = send_through_proxy({:setopts, [binary: true]})
      assert forwarded == {:setopts, [binary: true]}
    end

    test "forwards getopts unchanged" do
      {_reply, forwarded} = send_through_proxy(:getopts)
      assert forwarded == :getopts
    end
  end

  defp send_through_proxy(request) do
    test_pid = self()
    original_gl = Process.group_leader()

    fake_gl =
      spawn(fn ->
        receive do
          {:io_request, from, reply_as, captured} ->
            send(from, {:io_reply, reply_as, :ok})
            send(test_pid, {:captured, captured})
        end
      end)

    Process.group_leader(self(), fake_gl)
    {:ok, proxy} = GenServer.start_link(Yokai.IOProxy, :ok)

    ref = make_ref()
    send(proxy, {:io_request, self(), ref, request})

    result =
      receive do
        {:io_reply, ^ref, reply} ->
          receive do
            {:captured, forwarded} -> {reply, forwarded}
          after
            1000 -> raise "Timed out waiting for captured request"
          end
      after
        1000 -> raise "Timed out waiting for io_reply"
      end

    GenServer.stop(proxy)
    Process.group_leader(self(), original_gl)
    restore_logger_formatter()
    result
  end

  defp assert_proxy_translates(request, expected_output) do
    {reply, forwarded} = send_through_proxy(request)
    assert reply == :ok
    assert {:put_chars, :unicode, chars} = forwarded
    assert IO.chardata_to_string(chars) == expected_output
  end

  defp restore_logger_formatter do
    case :logger.get_handler_config(:default) do
      {:ok, %{formatter: {Yokai.IOProxy.LoggerFormatter, {orig_mod, orig_config}}}} ->
        :logger.update_handler_config(:default, :formatter, {orig_mod, orig_config})

      _ ->
        :ok
    end
  end
end

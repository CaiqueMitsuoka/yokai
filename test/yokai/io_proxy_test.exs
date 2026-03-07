defmodule Yokai.IOProxyTest do
  use ExUnit.Case

  describe "start/0" do
    test "sets a new group leader for the calling process" do
      original_gl = Process.group_leader()

      Yokai.IOProxy.start()
      proxy_gl = Process.group_leader()

      refute original_gl == proxy_gl
      assert Process.alive?(proxy_gl)

      Process.group_leader(self(), original_gl)
      restore_logger_formatter()
    end

    test "returns :ok" do
      original_gl = Process.group_leader()
      assert :ok = Yokai.IOProxy.start()
      Process.group_leader(self(), original_gl)
      restore_logger_formatter()
    end

    test "wraps the logger formatter" do
      original_gl = Process.group_leader()

      {:ok, %{formatter: {orig_mod, _}}} = :logger.get_handler_config(:default)

      Yokai.IOProxy.start()

      {:ok, %{formatter: {new_mod, {wrapped_mod, _}}}} = :logger.get_handler_config(:default)
      assert new_mod == Yokai.IOProxy.LoggerFormatter
      assert wrapped_mod == orig_mod

      Process.group_leader(self(), original_gl)
      restore_logger_formatter()
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

  # Sends a request through a real Yokai.IOProxy backed by a fake GL,
  # returns {reply, forwarded_request}.
  defp send_through_proxy(request) do
    test_pid = self()
    original_gl = Process.group_leader()

    # Fake GL that captures forwarded requests
    fake_gl =
      spawn(fn ->
        receive do
          {:io_request, from, reply_as, captured} ->
            send(from, {:io_reply, reply_as, :ok})
            send(test_pid, {:captured, captured})
        end
      end)

    # Set the fake GL as our group leader, then start the proxy on top of it
    Process.group_leader(self(), fake_gl)
    Yokai.IOProxy.start()

    proxy = Process.group_leader()
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

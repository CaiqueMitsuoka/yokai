defmodule Yokai.IOProxy do
  @moduledoc """
  A transparent IO group leader proxy that translates `\\n` → `\\r\\n` in output.

  In OTP 28's raw terminal mode, `\\n` only moves the cursor down without
  returning to column 0, causing "stepped" output. This proxy intercepts
  all `put_chars` IO requests and ensures proper `\\r\\n` line endings before
  forwarding to the original group leader.
  """

  def start do
    original_gl = Process.group_leader()
    pid = spawn_link(fn -> loop(original_gl) end)
    Process.group_leader(self(), pid)

    wrap_logger_formatter()

    :ok
  end

  defp wrap_logger_formatter do
    case :logger.get_handler_config(:default) do
      {:ok, %{formatter: {orig_mod, orig_config}}} ->
        :logger.update_handler_config(
          :default,
          :formatter,
          {Yokai.IOProxy.LoggerFormatter, {orig_mod, orig_config}}
        )

      _ ->
        :ok
    end
  end

  defp loop(original_gl) do
    receive do
      {:io_request, from, reply_as, request} ->
        translated = translate_request(request)
        send(original_gl, {:io_request, from, reply_as, translated})
        loop(original_gl)

      other ->
        send(original_gl, other)
        loop(original_gl)
    end
  end

  defp translate_request({:put_chars, encoding, chars}) do
    {:put_chars, encoding, translate_newlines(chars)}
  end

  defp translate_request({:put_chars, encoding, module, function, args}) do
    chars = apply(module, function, args)
    {:put_chars, encoding, translate_newlines(chars)}
  end

  defp translate_request({:requests, requests}) do
    {:requests, Enum.map(requests, &translate_request/1)}
  end

  defp translate_request(other), do: other

  defp translate_newlines(chars) do
    chars
    |> IO.chardata_to_string()
    |> String.replace("\r\n", "\n")
    |> String.replace("\n", "\r\n")
  end
end

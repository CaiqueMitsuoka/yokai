defmodule Yokai.IOProxy do
  use GenServer

  @moduledoc """
  A transparent IO group leader proxy that translates `\\n` → `\\r\\n` in output.

  In OTP 28's raw terminal mode, `\\n` only moves the cursor down without
  returning to column 0, causing "stepped" output. This proxy intercepts
  all `put_chars` IO requests and ensures proper `\\r\\n` line endings before
  forwarding to the original group leader.
  """

  def start_link(_opts \\ []) do
    GenServer.start_link(__MODULE__, :ok, name: __MODULE__)
  end

  def set_group_leader do
    proxy_pid = Process.whereis(__MODULE__)
    original_gl = Process.group_leader()

    if original_gl != proxy_pid do
      GenServer.call(__MODULE__, {:set_original_gl, original_gl})
    end

    Process.group_leader(self(), proxy_pid)
  end

  @impl true
  def init(:ok) do
    original_gl = Process.group_leader()
    wrap_logger_formatter()

    {:ok, %{original_gl: original_gl}}
  end

  @impl true
  def handle_call({:set_original_gl, gl}, _from, state) do
    {:reply, :ok, %{state | original_gl: gl}}
  end

  @impl true
  def handle_info({:io_request, from, reply_as, request}, state) do
    translated = translate_request(request)
    send(state.original_gl, {:io_request, from, reply_as, translated})

    {:noreply, state}
  end

  def handle_info(other, state) do
    send(state.original_gl, other)

    {:noreply, state}
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

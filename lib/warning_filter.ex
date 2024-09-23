defmodule WarningFilter do
  require Logger

  def filter_warnings do
    IO.inspect("Filtering warnings")
    :ok = Logger.add_translator({WarningFilter, :translate})
  end

  def restore_warnings do
    IO.inspect("Restoring warnings")
    :ok = Logger.remove_translator({WarningFilter, :translate})
  end

  def translate(_min_level, :warning, _kind, message) do
    IO.inspect(message, label: :message)

    if should_suppress_warning?(to_string(message)) do
      :skip
    else
      :none
    end
  end

  def translate(_, level, _, _), do: IO.inspect(level, label: :level)
  :none

  def translate({:warning, gl, {Logger, message, timestamp, metadata}}) do
    IO.inspect(message, label: :message)

    if should_suppress_warning?(to_string(message)) do
      :skip
    else
      {:warning, gl, {Logger, message, timestamp, metadata}}
    end
  end

  def translate(log_event), do: IO.inspect(log_event, label: :log_event)

  defp should_suppress_warning?(message) do
    String.contains?(message, "redefining module") and
      String.contains?(message, "(current version defined in memory)")
  end
end

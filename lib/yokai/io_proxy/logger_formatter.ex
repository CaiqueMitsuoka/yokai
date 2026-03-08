defmodule Yokai.IOProxy.LoggerFormatter do
  @moduledoc false

  def format(event, {original_mod, original_config}) do
    original_mod.format(event, original_config)
    |> IO.chardata_to_string()
    |> String.replace("\r\n", "\n")
    |> String.replace("\n", "\r\n")
  end
end

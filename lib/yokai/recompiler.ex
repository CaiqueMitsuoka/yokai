defmodule Yokai.Recompiler do
  @moduledoc """
  Recompiles the project
  """

  use GenServer
  require Logger

  alias Yokai.ExsRecompiler

  def start_link do
    GenServer.start_link(__MODULE__, %{}, name: __MODULE__)
  end

  def child_spec(_) do
    %{
      id: __MODULE__,
      start: {__MODULE__, :start_link, []}
    }
  end

  @impl true
  def init(_) do
    {:ok, %{}}
  end

  @impl true
  def handle_call(:code, _caller, state) do
    {:reply, compile_code(), state}
  end

  @impl true
  def handle_call({:tests, pattern}, _caller, state) do
    {:reply, ExsRecompiler.from_pattern(pattern), state}
  end

  defp compile_code do
    IEx.Helpers.recompile()
  end
end

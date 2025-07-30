defmodule Yokai.Recompiler do
  @moduledoc """
  Recompiles the project
  """

  use GenServer
  require Logger

  alias Yokai.ExsRecompiler

  def start_link(opts \\ %{}) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  def child_spec(opts) do
    %{
      id: __MODULE__,
      start: {__MODULE__, :start_link, [opts]}
    }
  end

  def recompile_all(opts \\ %{}) do
    timeout = Map.get(opts, :compile_timeout)
    test_files_paths = Map.get(opts, :test_files_paths)

    GenServer.call(__MODULE__, :code, timeout)
    GenServer.call(__MODULE__, {:tests, test_files_paths}, timeout)
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
  def handle_call({:tests, test_files_paths}, _caller, state) do
    {:reply, ExsRecompiler.from_pattern(test_files_paths), state}
  end

  defp compile_code do
    IEx.Helpers.recompile()
  end
end

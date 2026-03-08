defmodule Yokai.TUI do
  use GenServer

  alias Yokai.Options.CLIParser

  @commands %{
    "w" =>
      {{:update_options, "Enter the new test files pattern:",
        &__MODULE__.format_test_pattern_update/2}, "Update the test files pattern"},
    "a" => {{:once_with_options, &__MODULE__.run_all/1}, "Run all tests once"},
    "r" => {:run, "Rerun tests"},
    "q" => {:quit, "Quit"}
  }

  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  def subscribe(pid \\ self()) do
    GenServer.call(__MODULE__, {:subscribe, pid})
  end

  def terminal do
    GenServer.call(__MODULE__, :terminal)
  end

  @impl true
  def init(opts) do
    terminal = opts[:terminal] || Termite.Terminal.start()

    {:ok, %{terminal: terminal, subscriber: nil}}
  end

  @impl true
  def handle_call({:subscribe, pid}, _from, state) do
    Process.monitor(pid)

    {:reply, {:ok, state.terminal}, %{state | subscriber: pid}}
  end

  def handle_call(:terminal, _from, state) do
    {:reply, state.terminal, state}
  end

  @impl true
  def handle_info({ref, _} = msg, %{terminal: %{reader: reader}, subscriber: subscriber} = state)
      when ref == reader and subscriber != nil do
    send(subscriber, msg)

    {:noreply, state}
  end

  def handle_info({:DOWN, _, :process, pid, _}, %{subscriber: pid} = state) do
    state = Map.put(state, :subscriber, nil)

    {:noreply, state}
  end

  def handle_info(_msg, state) do
    {:noreply, state}
  end

  def show_menu do
    build_menu_text() |> puts()
  end

  def validate_command(input, options) do
    trimmed_input = String.trim(input)

    case Map.get(@commands, trimmed_input) do
      {command, _description} when is_atom(command) ->
        {:ok, command}

      {{:update_options, _, _} = command, _description} ->
        update_command(command, options)

      {{:once_with_options, options_updater}, _description} ->
        {:ok, {:run_once_with_opts, options_updater.(options)}}

      nil ->
        {:error, "Invalid command '#{trimmed_input}'. Please choose from the available options."}
    end
  end

  defp update_command({:update_options, question, formatter} = command, options) do
    IO.write("\n" <> question <> " ")
    input = IO.gets("") |> String.trim()
    IO.puts("")

    case formatter.(input, options) do
      {:error, msg} ->
        puts(msg)
        update_command(command, options)

      result ->
        result
    end
  end

  def build_menu_text do
    commands =
      @commands
      |> Enum.map(fn
        {key, {_command, description}} ->
          "#{key} - #{description}"
      end)
      |> Enum.join("\n")

    "\nWatching for changes...\n\nCommands:\n#{commands}"
  end

  def format_test_pattern_update(input, options) do
    options_changes = CLIParser.test_patterns_to_map([input])

    new_options = Map.merge(options, options_changes)
    {:ok, {:run_with_opts, new_options}}
  end

  def run_all(options) do
    options_with_run_all =
      CLIParser.default_test_pattern()
      |> CLIParser.test_patterns_to_map()

    Map.merge(options, options_with_run_all)
  end

  def puts(string) do
    IO.puts(string)
  end

  def clear do
    IO.write("\e[2J\e[H")
  end
end

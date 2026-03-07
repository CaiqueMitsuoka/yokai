defmodule Yokai.TUI do
  alias Yokai.Options.CLIParser
  alias Yokai.IOProxy

  @commands %{
    "w" =>
      {{:update_options, "Enter the new test files pattern:",
        &__MODULE__.format_test_pattern_update/2}, "Update the test files pattern"},
    "a" => {{:once_with_options, &__MODULE__.run_all/1}, "Run all tests once"},
    "r" => {:run, "Rerun tests"},
    "q" => {:quit, "Quit"}
  }

  def start do
    terminal = Termite.Terminal.start()
    IOProxy.start()

    {:ok, terminal}
  end

  def listen_new_command(options) do
    main_process = self()

    Task.async(fn ->
      command = listen_with_menu(options)
      send(main_process, command)
    end)
  end

  def show_menu do
    build_menu_text() |> puts()
  end

  def listen_with_menu(options) do
    show_menu()

    listen_for_keypress(options)
  end

  defp listen_for_keypress(options) do
    case Termite.Terminal.poll(options.terminal) do
      {:data, key} ->
        key = String.trim(key)

        case validate_command(key, options) do
          {:ok, command} -> command
          {:error, _msg} -> listen_for_keypress(options)
        end

      _ ->
        listen_for_keypress(options)
    end
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

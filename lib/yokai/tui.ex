defmodule Yokai.TUI do
  alias Yokai.Options.CLIParser

  @commands %{
    "w" =>
      {{:update_options, "Enter the new test files pattern:",
        &__MODULE__.format_test_pattern_update/2}, "Update the test files pattern"},
    "a" => {{:once_with_options, &__MODULE__.run_all/1}, "Run all tests once"},
    "r" => {:run, "Rerun tests"},
    "q" => {:quit, "Quit"}
  }

  def listen_new_command(options) do
    main_process = self()

    Task.async(fn ->
      command = listen_with_menu(options)
      send(main_process, command)
    end)
  end

  def listen_with_menu(options) do
    build_menu_text() |> Owl.IO.puts()

    Owl.IO.input(cast: &validate_command(&1, options))
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
    input = Owl.IO.input(label: question)

    case formatter.(input, options) do
      {:error, msg} ->
        Owl.IO.inspect(msg)
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
          [
            Owl.Data.tag(key, :bright),
            " - ",
            description
          ]
      end)
      |> Enum.intersperse("\n")

    []
    |> Kernel.++(["\nWatching for changes...\n\n"])
    |> Kernel.++(["Commands:\n"])
    |> Kernel.++(commands)
    |> List.flatten()
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
    Owl.IO.puts([string])
  end

  def clear do
    IO.write("\e[2J\e[H")
  end
end

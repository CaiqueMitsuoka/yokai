defmodule Yokai.TUI do
  alias Yokai.Options.CLIParser

  @commands %{
    "w" =>
      {{:update_options, "Enter the new test files pattern:",
        &__MODULE__.format_test_pattern_update/1}, "Update the test files pattern"},
    "r" => {:run, "Rerun tests"},
    "q" => {:quit, "Quit"}
  }

  def listen_new_command do
    main_process = self()

    Task.async(fn ->
      command = listen_with_menu()
      send(main_process, command)
    end)
  end

  def listen_with_menu do
    build_menu_text() |> Owl.IO.puts()

    Owl.IO.input(cast: &validate_command/1)
  end

  def validate_command(input) do
    trimmed_input = String.trim(input)

    case Map.get(@commands, trimmed_input) do
      {command, _description} when is_atom(command) ->
        {:ok, command}

      {command, _description} when is_tuple(command) ->
        update_command(command)

      nil ->
        {:error, "Invalid command '#{trimmed_input}'. Please choose from the available options."}
    end
  end

  defp update_command({:update_options, question, formatter} = command) do
    input = Owl.IO.input(label: question)

    case formatter.(input) do
      {:error, msg} ->
        Owl.IO.inspect(msg)
        update_command(command)

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

  def format_test_pattern_update(input) do
    new_opts = CLIParser.test_patterns_to_map([input])

    {:ok, {:update_options, new_opts}}
  end

  def puts(string) do
    Owl.IO.puts([string])
  end

  def clear do
    IO.write("\e[2J\e[H")
  end
end

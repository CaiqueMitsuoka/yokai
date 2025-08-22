defmodule Yokai.TUI do
  @commands %{
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
    menu_text = build_menu_text()

    Owl.IO.input(
      label: menu_text,
      cast: &validate_command/1
    )
  end

  def validate_command(input) do
    trimmed_input = String.trim(input)

    case Map.get(@commands, trimmed_input) do
      {command, _description} ->
        {:ok, command}

      nil ->
        {:error, "Invalid command '#{trimmed_input}'. Please choose from the available options."}
    end
  end

  def build_menu_text do
    commands_text =
      @commands
      |> Enum.map(fn {key, {_command, description}} -> "#{key} - #{description}" end)
      |> Enum.join("\n")

    """

    Watching for changes...

    Commands:
    #{commands_text}
    """
  end

  def clear do
    IO.write("\e[2J\e[H")
  end
end

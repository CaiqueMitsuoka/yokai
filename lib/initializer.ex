defmodule Yokai.Initializer do
  require Logger

  alias Yokai.TUI

  def run(opts) do
    with _ <- Mix.Task.run("loadconfig"),
         :ok <- Mix.Task.run("app.config"),
         {:ok, [:file_system]} <- Application.ensure_all_started(:file_system),
         {:ok, _} <- start_application() do
      TUI.puts("Starting Yokai...")

      opts
    else
      :error ->
        Logger.error("Error starting Yokai.")

        System.stop(1)

        %{opts | exit: true}

      {:error, apps} ->
        Logger.error("Error starting applications: #{inspect(apps)}")

        System.stop(1)

        %{opts | exit: true}
    end
  end

  defp start_application do
    # Stop Logger so it restarts with the project's config (e.g., level
    # from config/test.exs). This mirrors what Mix.Tasks.App.Start does —
    # without it, Logger keeps its boot-time defaults and ignores the
    # project's configured level.
    Logger.App.stop()

    Mix.Project.config()
    |> Keyword.get(:app)
    |> Application.ensure_all_started()
  end

  def loadpaths() do
    case Mix.Task.run("loadpaths") do
      :noop -> :ok
      :ok -> :ok
      _ -> :error
    end
  end
end

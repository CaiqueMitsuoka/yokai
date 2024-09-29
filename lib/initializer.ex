defmodule Yokai.Initializer do
  require Logger

  def run(opts) do
    with _ <- Mix.Task.run("loadconfig"),
         :ok <- Mix.Task.run("app.config"),
         {:ok, [:file_system]} <- Application.ensure_all_started(:file_system),
         {:ok, _} <- start_application(),
         :ok <- ExUnit.start(auto_run: false) do
      Logger.info("Starting Yokai...")
      |> IO.inspect(label: :exunit_start)

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

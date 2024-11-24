defmodule Yokai.Application do
  use Application
  require Logger

  def start(_type, _args) do
    Logger.info("Starting Yokai app...")
    ensure_started()
    children = []

    opts = [strategy: :one_for_one, name: Yokai.Supervisor]
    Supervisor.start_link(children, opts)
  end

  def ensure_started do
    Application.ensure_all_started(:file_system)
  end
end

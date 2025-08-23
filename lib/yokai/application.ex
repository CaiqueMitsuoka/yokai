defmodule Yokai.Application do
  use Application
  require Logger

  alias Yokai.TUI

  def start(_type, _args) do
    TUI.puts("Starting Yokai app...")
    ensure_started()
    children = [Yokai.Recompiler]

    opts = [strategy: :one_for_one, name: Yokai.Supervisor]
    Supervisor.start_link(children, opts)
  end

  def ensure_started do
    Application.ensure_all_started(:file_system)
  end
end

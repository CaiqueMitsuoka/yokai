defmodule Yokai.Options do
  @moduledoc """
  Module for handling Yokai configurations state.
  The defaults, Application env and it's changes.
  """

  defstruct test_patterns: [],
            test_files_paths: [],
            watch_folders: ["lib", "test"],
            exit: false,
            compile_timeout: 30_000
end

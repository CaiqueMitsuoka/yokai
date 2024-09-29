defmodule Yokai.Options do
  @moduledoc """
  Module for handling Yokai configurations state.
  The defaults, Application env and it's changes.
  """

  defstruct test_patterns: [],
            watch_folders: ["lib", "test"],
            exit: false
end

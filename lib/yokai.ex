defmodule Yokai do
  @moduledoc """
  # Yokai

  Yokai is an alternative test runner for ExUnit based on file watcher. It watches for code changes and changes in selected test files to auto trigger a new test run with hot reloading, avoiding a cold start of the app/VM. The BEAM way.

  ## Installation

  Add `yokai` to your list of dependencies in `mix.exs`:

  ```elixir
  # You need this to make mix watch apply MIX_ENV=test for you.
  def cli do
    [
      preferred_envs: [{:watch, :test}]
    ]
  end

  def deps do
    [
      {:yokai, "~> 0.3.0"}
    ]
  end
  ```

  ## Usage

  ```shell
  # Run all tests and watch for changes
  mix watch

  # Run only this test file and watch for changes
  mix watch test/module_name.exs

  # Run all tests following a wildcard pattern
  mix watch test/domain/*

  # Increase the compile timeout for big projects
  mix watch --compile-timeout 60
  ```

  ## CLI Options

  * `--watch-folders` (`-w`) - Comma-separated list of folders to watch for changes (default: "lib,test")
  * `--test-patterns` (`-t`) - Comma-separated list of test patterns to run (default: "test/**/*_test.exs")
  * `--compile-timeout` (`-c`) - Compilation timeout in seconds (default: 30)

  ## Examples

  ```shell
  # Watch specific folders
  mix watch --watch-folders lib,test,config

  # Run specific test patterns
  mix watch --test-patterns "test/unit/**/*_test.exs,test/integration/**/*_test.exs"

  # Combine options
  mix watch test/unit test/integration -w lib,test -c 45
  ```

  ## Reason

  The point is to have a faster iteration when developing tests/changes or applying TDD.

  When talking about this idea it always comes up that you need to reload the environment when you change a config. To this there are 2 points against:
  - Most of the time you are not changing configuration between runs, but when you do: `mix test` is still there, exactly the same.
  - The hot reload from Phoenix is good enough for most apps and workflows. This applies the same rules but for tests.
  """
end

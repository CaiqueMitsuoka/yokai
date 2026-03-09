# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Yokai is an Elixir test runner and file watcher that provides hot-reloading for tests. It monitors file changes in the `lib` and `test` directories and automatically reruns tests without cold-starting the VM, improving TDD iteration speed.

## Key Architecture Components

### Core Modules Structure
- **Mix.Tasks.Watch** (`lib/mix/tasks/watch.ex`): The main Mix task that orchestrates file watching and test execution
- **Yokai.Application** (`lib/yokai/application.ex`): OTP Application that manages the supervision tree with Yokai.IOProxy, Yokai.TUI, and Yokai.Recompiler
- **Yokai.TUI** (`lib/yokai/tui.ex`): GenServer managing the terminal UI — starts Termite for raw keystroke input, forwards terminal events to a subscriber, and handles the interactive command menu
- **Yokai.IOProxy** (`lib/yokai/io_proxy/io_proxy.ex`): GenServer that acts as a group leader proxy, translating `\n` → `\r\n` in all IO output. Required because OTP 28's raw terminal mode (via Termite's Shell adapter) doesn't perform newline translation, causing "stepped" output. Also wraps the Logger formatter via `Yokai.IOProxy.LoggerFormatter` for the same translation on Logger output
- **Yokai.Runner** (`lib/yokai/runner.ex`): Coordinates recompilation and test execution through ExUnit
- **Yokai.Recompiler** (`lib/yokai/recompiler.ex`): GenServer that handles hot recompilation of project code using `IEx.Helpers.recompile/0`
- **Yokai.ExsRecompiler** (`lib/yokai/exs_recompiler.ex`): Handles recompilation of `.exs` test files and module extraction
- **Yokai.Options** (`lib/yokai/options/`): CLI parsing and path resolution for test patterns and watch folders

### Supervision Tree
All long-lived processes are supervised under `Yokai.Supervisor` (one_for_one):
1. `Yokai.IOProxy` — must start first so its group leader proxy is available
2. `Yokai.TUI` — starts Termite terminal, provides keystroke input
3. `Yokai.Recompiler` — handles hot code reloading

### Data Flow
1. `mix watch` parses CLI options and starts the application (supervision tree)
2. IOProxy installs itself as group leader proxy and wraps the Logger formatter
3. TUI starts the Termite terminal for raw keystroke input
4. File changes trigger recompilation through Recompiler GenServer
5. Runner extracts test modules from specified files and runs via ExUnit
6. Process repeats on subsequent file changes

## Development Commands

```shell
# Run the test watcher (main functionality)
mix watch

# Run specific test files
mix watch test/my_test.exs

# Run tests matching patterns
mix watch test/domain/*

# Configure watch folders and compile timeout
mix watch --watch-folders lib,test,config --compile-timeout 60

# Standard Elixir commands
mix compile
mix test
mix docs
```

## Test Configuration

The project uses ExUnit with the following structure:
- Test files: `test/**/*_test.exs` (default pattern)
- Test helper: `test/test_helper.exs`
- Watch folders: `lib,test` (default)

Configure `mix.exs` CLI settings for proper test environment:
```elixir
def cli do
  [preferred_envs: [{:watch, :test}]]
end
```

## Dependencies

- `file_system`: File watching functionality
- `termite`: Terminal raw mode and keystroke input (uses Shell adapter on OTP 28)
- `ex_doc`: Documentation generation (dev only)

## Important Patterns

### IO Newline Translation (OTP 28)
On OTP 28, Termite's Shell adapter uses `:shell.start_interactive({:noshell, :raw})` for raw keystroke input. In raw mode, `\n` only moves the cursor down without returning to column 0. `Yokai.IOProxy` solves this at three levels:
- **Group leader proxy**: Intercepts `put_chars` IO requests and translates `\n` → `\r\n` before forwarding. Callers must call `Yokai.IOProxy.set_group_leader/0` to opt in. Any GenServer that produces IO output (e.g. `Yokai.Recompiler`) must call `set_group_leader/0` in its `init/1`.
- **Logger formatter wrapper**: `Yokai.IOProxy.LoggerFormatter` wraps the `:default` Logger handler's formatter since Logger writes from its own handler process via `standard_io` (the `user` process), bypassing the group leader proxy. The wrapper can be unwrapped by tests (e.g. `Yokai.IOProxySyncTest` restores the original formatter on exit). `Runner.start/1` calls `IOProxy.ensure_logger_wrapped/0` before each run to re-wrap if needed.
- **stderr proxy**: A lightweight process registered as `:standard_error` that intercepts IO requests and translates newlines before forwarding to the original stderr process. This catches compiler warnings, `IO.warn/2`, and any other stderr output that bypasses both the group leader and Logger.

#### Debugging "stepped" output
If output appears staggered/stepped (each line indented further right), it means some IO path is emitting bare `\n` without `\r`. Check these in order:
1. **Which process?** — If the output comes from a GenServer, ensure it calls `IOProxy.set_group_leader/0` in its `init/1`.
2. **Logger?** — Run `:logger.get_handler_config(:default)` and verify the formatter is `{Yokai.IOProxy.LoggerFormatter, _}`. If not, something unwrapped it (tests, `capture_log`, or handler reconfiguration). `ensure_logger_wrapped/0` should be called before the affected code path.
3. **stderr?** — Verify `Process.whereis(:standard_error)` is the proxy, not the original OTP process. Compiler warnings and `IO.warn` go through stderr.

### Test Module Discovery
Yokai's runner extracts all modules from `*_test.exs` files and passes them to ExUnit. Do **not** define non-test modules (helpers, fakes) inside test files — they will be picked up and cause `not a ExUnit.Case module` errors. Place test helpers in `test/test_helper.exs` instead.

Hot reloading works by leveraging `IEx.Helpers.recompile/0` for project code and custom `.exs` file recompilation for test modules.
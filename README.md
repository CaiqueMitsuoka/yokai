# Yokai
[![Hex.pm](https://img.shields.io/hexpm/v/yokai.svg)](https://hex.pm/packages/yokai)
[![Downloads](https://img.shields.io/hexpm/dt/yokai.svg)](https://hex.pm/packages/yokai)
[![Documentation](https://img.shields.io/badge/documentation-gray)](https://hexdocs.pm/yokai)

Yokai is an alternative test runner for ExUnit base on file watcher. Watchs for code changes and changes in the selected test files to auto trigger a new testa run hot reloading the code avoiding a cold start of the app/vm. The BEAM way.

## Installation

```elixir
# You need this to mix watch apply MIX_ENV=test for you.
def cli do
  [
    preferred_envs: [{:watch, :test}]
  ]
end

def deps do
  [
    {:yokai, "~> 0.3.1"}
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

# Increate the compile timeout for big projects.
mix watch --compile-timeout 60
```

While running, all changes to any file at `lib/` or `test/` will trigger a run.

But while it waits for a file change, you can enter commands yourself.

### Menu

| Command | Description                   |
| ------- | ----------------------------- |
| a       | Run all tests once            |
| q       | Quit                          |
| r       | Rerun tests                   |
| w       | Update the test files pattern |

## Reason

The point is to have a faster iteration for then developing test/changes or applying TDD.

When talking about this idea it always come up that you need to reload the environment when you change a config. And
to this there is 2 points against.
 - Most of the time you are not changing configuration between runs, but when you do: mix test still there, exactly the same.
 - The hot reload from Phoenix is good enough for most apps and workflows. This applies the same rules but for tests.

## Goals

Have a fast code reloader and a nice CLI to quick iterate on development.

- [x] Hot reload project code before each run
- [x] Hot reload test file before each run
- [x] Accept test file patterns to select test e.g accept `test/*/sample*`
- [x] Option to clear console between run
- [ ] Keypress to trigger a run(Partially implemented, requires enter)
- [ ] Keypress to run all tests(Partially implemented, requires enter)
- [ ] Keypress to redefine the pattern(Partially implemented, requires enter)
- [ ] MCP server/tool for client to collect latest test run results.
- [ ] MCP tool to redefine runned configuration

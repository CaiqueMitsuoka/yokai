defmodule Yokai.Options.CLIParser do
  alias Yokai.Options
  alias Yokai.Options.PathResolver

  def parse(args) do
    {opts, files, _} =
      OptionParser.parse(args,
        strict: [
          watch_folders: :string,
          test_patterns: :string,
          compile_timeout: :integer
        ],
        aliases: [
          w: :watch_folders,
          t: :test_patterns,
          c: :compile_timeout
        ]
      )

    test_patterns = parse_test_patterns(files, opts)
    test_map = test_patterns_to_map(test_patterns)
    watch_folders = Keyword.get(opts, :watch_folders, "lib,test") |> String.split(",")
    compile_timeout = Keyword.get(opts, :compile_timeout, 30) * 1000

    %Options{
      watch_folders: watch_folders,
      compile_timeout: compile_timeout
    }
    |> Map.merge(test_map)
  end

  def test_patterns_to_map(test_patterns) do
    test_files_paths = PathResolver.resolve(test_patterns)

    %{
      test_patterns: test_patterns,
      test_files_paths: test_files_paths
    }
  end

  defp parse_test_patterns(files, opts) do
    case Keyword.get(opts, :test_patterns, []) do
      patterns when is_binary(patterns) -> String.split(patterns, ",")
      patterns -> patterns
    end
    |> Kernel.++(files)
    |> case do
      [] -> ["test/**/*_test.exs"]
      test_patterns -> test_patterns
    end
  end
end

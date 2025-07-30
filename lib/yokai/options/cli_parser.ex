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

    test_patterns =
      Keyword.get(opts, :test_patterns, "test/**/*_test.exs")
      |> String.split(",")
      |> Kernel.++(files)

    test_files_paths = PathResolver.resolve(test_patterns)
    watch_folders = Keyword.get(opts, :watch_folders, "lib,test") |> String.split(",")
    compile_timeout = Keyword.get(opts, :compile_timeout, 30) * 1000

    %Options{
      watch_folders: watch_folders,
      test_patterns: test_patterns,
      test_files_paths: test_files_paths,
      compile_timeout: compile_timeout
    }
  end
end

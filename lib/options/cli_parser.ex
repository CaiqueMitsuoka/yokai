defmodule Yokai.Options.CLIParser do
  alias Yokai.Options

  def parse(args) do
    {opts, files, _} =
      OptionParser.parse(args,
        strict: [
          watch_folders: :string,
          test_patterns: :string
        ],
        aliases: [
          w: :watch_folders,
          t: :test_patterns
        ]
      )

    test_patterns =
      Keyword.get(opts, :test_patterns, "test/**/*_test.exs")
      |> String.split(",")
      |> Kernel.++(files)

    watch_folders = Keyword.get(opts, :watch_folders, "lib,test") |> String.split(",")

    %Options{watch_folders: watch_folders, test_patterns: test_patterns}
  end
end

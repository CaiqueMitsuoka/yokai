defmodule Yokai.Options.PathResolver do
  @doc """
  Resolves a list of patterns/paths to actual .exs file paths.

  ## Examples

      iex> PathResolver.resolve(["test/*"])
      ["test/sample_test.exs", "test/another_test.exs"]
      
      iex> PathResolver.resolve(["test/specific_test.exs"])
      ["test/specific_test.exs"]
  """
  def resolve(patterns) when is_list(patterns) do
    patterns
    |> Enum.flat_map(&resolve_single/1)
    |> Enum.uniq()
    |> Enum.sort()
  end

  defp resolve_single(pattern) do
    cond do
      String.contains?(pattern, "*") ->
        resolve_glob_pattern(pattern)

      File.exists?(pattern) ->
        if File.dir?(pattern) do
          resolve_directory(pattern)
        else
          [pattern]
        end

      true ->
        []
    end
  end

  defp resolve_glob_pattern(pattern) do
    pattern
    |> Path.wildcard()
    |> Enum.filter(&String.ends_with?(&1, ".exs"))
    |> Enum.filter(&File.regular?/1)
  end

  defp resolve_directory(dir_path) do
    dir_path
    |> Path.join("**/*.exs")
    |> Path.wildcard()
    |> Enum.filter(&File.regular?/1)
  end
end

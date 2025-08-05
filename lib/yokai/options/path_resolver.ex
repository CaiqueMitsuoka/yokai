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
      glob_pattern?(pattern) ->
        resolve_glob_pattern(pattern)

      existing_directory?(pattern) ->
        resolve_directory(pattern)

      existing_file?(pattern) ->
        [pattern]

      true ->
        []
    end
  end

  defp glob_pattern?(pattern), do: String.contains?(pattern, "*")

  defp existing_directory?(pattern), do: File.exists?(pattern) and File.dir?(pattern)

  defp existing_file?(pattern), do: File.exists?(pattern) and File.regular?(pattern)

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

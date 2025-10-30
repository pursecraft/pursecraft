defmodule Credo.Check.PurseCraft.RequireAsyncTests do
  @moduledoc false
  use Credo.Check,
    base_priority: :high,
    category: :refactoring,
    explanations: [
      check: """
      Test cases must be marked `async: true` for concurrent execution.

      ## Why This Matters

      Async tests run concurrently, dramatically speeding up test suite execution.
      All tests should use `async: true` unless they have specific requirements
      that absolutely prevent concurrent execution.

      ## Bad Example

          defmodule MyApp.SomeTest do
            use MyApp.DataCase, async: false
          end

      ## Good Example

          defmodule MyApp.SomeTest do
            use MyApp.DataCase, async: true
          end

      ## If You Need async: false

      If you have a legitimate reason to use `async: false`, you must disable
      this check for that specific file using:

          # credo:disable-for-this-file Credo.Check.PurseCraft.RequireAsyncTests
          defmodule MyApp.SomeTest do
            use MyApp.DataCase, async: false
          end

      Valid reasons are rare and typically include:
      - Using Mimic or other global mocking libraries
      - Modifying global application state
      - Testing process registration with named processes

      In most cases, you should refactor the test to avoid these patterns.
      """
    ]

  alias Credo.SourceFile

  @doc false
  @impl Credo.Check
  def run(%SourceFile{} = source_file, params) do
    issue_meta = IssueMeta.for(source_file, params)

    path = source_file.filename

    if test_file?(path) do
      Credo.Code.prewalk(source_file, &traverse(&1, &2, issue_meta))
    else
      []
    end
  end

  defp test_file?(path) do
    String.ends_with?(path, "_test.exs")
  end

  # Pattern: use SomeCase, async: false
  defp traverse({:use, meta, [{_, _meta, _module_path}, options]} = ast, issues, issue_meta) when is_list(options) do
    case Keyword.get(options, :async) do
      false ->
        {ast, [issue_for(issue_meta, meta[:line]) | issues]}

      _true_or_nil ->
        {ast, issues}
    end
  end

  defp traverse(ast, issues, _issue_meta) do
    {ast, issues}
  end

  defp issue_for(issue_meta, line_no) do
    format_issue(
      issue_meta,
      message:
        "Tests must use `async: true`. If `async: false` is absolutely required, disable this check for the file with: # credo:disable-for-this-file Credo.Check.PurseCraft.RequireAsyncTests",
      line_no: line_no
    )
  end
end

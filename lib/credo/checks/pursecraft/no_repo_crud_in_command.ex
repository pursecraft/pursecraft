defmodule Credo.Check.PurseCraft.NoRepoCrudInCommand do
  @moduledoc false
  use Credo.Check,
    base_priority: :high,
    category: :design,
    explanations: [
      check: """
      Command modules should use Repository modules instead of calling Repo directly.

      ## Architecture Pattern

      Commands are responsible for business logic and orchestration.
      They should delegate all data access to Repository modules.

      Only `Repo.transaction` and `Repo.rollback` are allowed for transaction management.

      ## Bad Example

          defmodule MyApp.SomeCommand do
            def call(scope, attrs) do
              %Resource{}
              |> Resource.changeset(attrs)
              |> Repo.insert()
            end
          end

      ## Good Example

          defmodule MyApp.SomeCommand do
            alias MyApp.SomeRepository

            def call(scope, attrs) do
              SomeRepository.create(attrs)
            end
          end

      ## Allowed Transaction Management

          defmodule MyApp.SomeCommand do
            def call(scope, attrs) do
              Repo.transaction(fn ->
                # business logic using repositories
              end)
            end
          end
      """
    ]

  alias Credo.SourceFile

  @doc false
  @impl Credo.Check
  def run(%SourceFile{} = source_file, params) do
    issue_meta = IssueMeta.for(source_file, params)

    path = source_file.filename

    if command_module?(path) and not test_file?(path) and not search_context?(path) do
      Credo.Code.prewalk(source_file, &traverse(&1, &2, issue_meta))
    else
      []
    end
  end

  defp command_module?(path) do
    String.contains?(path, "/commands/") and String.ends_with?(path, ".ex")
  end

  defp test_file?(path) do
    String.contains?(path, "/test/")
  end

  defp search_context?(path) do
    String.contains?(path, "/search/")
  end

  defp traverse(
         {{:., _dot_meta, [{:__aliases__, _alias_meta, [:Repo]}, method]}, _call_meta, _args} = ast,
         issues,
         _issue_meta
       )
       when method in [:transaction, :rollback] do
    {ast, issues}
  end

  defp traverse({{:., _dot_meta, [{:__aliases__, _alias_meta, [:Repo]}, method]}, meta, _args} = ast, issues, issue_meta) do
    {ast, [issue_for(issue_meta, meta[:line], method) | issues]}
  end

  defp traverse(ast, issues, _issue_meta) do
    {ast, issues}
  end

  defp issue_for(issue_meta, line_no, method) do
    format_issue(
      issue_meta,
      message:
        "Do not use Repo.#{method} in Command modules. Commands should use Repository modules for data access. Only Repo.transaction and Repo.rollback are allowed.",
      line_no: line_no
    )
  end
end

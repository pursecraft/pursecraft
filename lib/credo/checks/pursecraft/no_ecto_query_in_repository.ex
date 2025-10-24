defmodule Credo.Check.PurseCraft.NoEctoQueryInRepository do
  @moduledoc false
  use Credo.Check,
    base_priority: :high,
    category: :design,
    explanations: [
      check: """
      Repository modules should use Query modules instead of importing Ecto.Query.

      ## Architecture Pattern

      Repositories are responsible for executing queries and managing data persistence.
      They should delegate query construction to Query modules, not build queries themselves.

      ## Bad Example

          defmodule MyApp.SomeRepository do
            import Ecto.Query

            def list_by_workspace(workspace_id) do
              from(r in Resource, where: r.workspace_id == ^workspace_id)
              |> Repo.all()
            end
          end

      ## Good Example

          defmodule MyApp.SomeRepository do
            alias MyApp.SomeQuery

            def list_by_workspace(workspace_id) do
              workspace_id
              |> SomeQuery.by_workspace_id()
              |> Repo.all()
            end
          end

      ## Exception

      SearchEntityRepository is exempt due to its polymorphic entity loading requirements.
      """
    ]

  @doc false
  @impl Credo.Check
  def run(%SourceFile{} = source_file, params) do
    issue_meta = IssueMeta.for(source_file, params)

    path = source_file.filename

    if repository_module?(path) and not exception?(path) and not test_file?(path) do
      Credo.Code.prewalk(source_file, &traverse(&1, &2, issue_meta))
    else
      []
    end
  end

  defp repository_module?(path) do
    String.contains?(path, "/repositories/") and String.ends_with?(path, "_repository.ex")
  end

  defp exception?(path) do
    String.contains?(path, "search_entity_repository.ex") or
      String.contains?(path, "entity_repository.ex")
  end

  defp test_file?(path) do
    String.contains?(path, "/test/")
  end

  defp traverse({:import, meta, [{:__aliases__, _alias_meta, [:Ecto, :Query]}]} = ast, issues, issue_meta) do
    {ast, [issue_for(issue_meta, meta[:line]) | issues]}
  end

  defp traverse(ast, issues, _issue_meta) do
    {ast, issues}
  end

  defp issue_for(issue_meta, line_no) do
    format_issue(
      issue_meta,
      message: "Repository modules must use Query modules, not import Ecto.Query. Extract query logic to a Query module.",
      line_no: line_no
    )
  end
end

defmodule Credo.Check.PurseCraft.NoEctoQueryInCommand do
  @moduledoc false
  use Credo.Check,
    base_priority: :high,
    category: :design,
    explanations: [
      check: """
      Command modules should use Repository modules instead of importing Ecto.Query or Query modules.

      ## Architecture Pattern

      Commands are responsible for business logic and orchestration.
      They should delegate data access to Repository modules, not build queries themselves.

      ## Bad Example

          defmodule PurseCraft.Accounting.Commands.Accounts.ListAccounts do
            import Ecto.Query
            alias PurseCraft.Accounting.Queries.AccountQuery

            def call(scope, workspace) do
              from(a in Account, where: a.workspace_id == ^workspace.id)
              |> Repo.all()
            end
          end

      ## Good Example

          defmodule PurseCraft.Accounting.Commands.Accounts.ListAccounts do
            alias PurseCraft.Accounting.Repositories.AccountRepository

            def call(scope, workspace) do
              AccountRepository.list_by_workspace(workspace.id)
            end
          end
      """
    ]

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

  defp traverse({:import, meta, [{:__aliases__, _alias_meta, [:Ecto, :Query]}]} = ast, issues, issue_meta) do
    {ast, [issue_for_import(issue_meta, meta[:line]) | issues]}
  end

  defp traverse({:alias, meta, [{:__aliases__, _alias_meta, module_parts}]} = ast, issues, issue_meta) do
    if query_module?(module_parts) do
      {ast, [issue_for_query_alias(issue_meta, meta[:line]) | issues]}
    else
      {ast, issues}
    end
  end

  defp traverse(ast, issues, _issue_meta) do
    {ast, issues}
  end

  defp query_module?(module_parts) do
    case List.last(module_parts) do
      atom when is_atom(atom) ->
        atom
        |> Atom.to_string()
        |> String.ends_with?("Query")

      _other ->
        false
    end
  end

  defp issue_for_import(issue_meta, line_no) do
    format_issue(
      issue_meta,
      message:
        "Command modules must use Repository modules, not import Ecto.Query. Move query logic to a Query module and use a Repository to execute it.",
      line_no: line_no
    )
  end

  defp issue_for_query_alias(issue_meta, line_no) do
    format_issue(
      issue_meta,
      message:
        "Command modules must use Repository modules, not Query modules directly. Use a Repository module to execute queries.",
      line_no: line_no
    )
  end
end

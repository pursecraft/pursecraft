defmodule Credo.Check.PurseCraft.NoPolicyOutsideCommand do
  @moduledoc false
  use Credo.Check,
    base_priority: :high,
    category: :design,
    explanations: [
      check: """
      Policy modules should only be used in Command modules.

      ## Architecture Pattern

      Authorization policies enforce access control and should only be called
      from Command modules that orchestrate business logic. Other layers
      (Repositories, Queries, Schemas, etc.) should not perform authorization.

      ## Bad Example

          defmodule PurseCraft.Accounting.Repositories.AccountRepository do
            alias PurseCraft.Accounting.Policy

            def list(scope) do
              Policy.authorize(scope, :account, :read)
              # ...
            end
          end

      ## Good Example

          defmodule PurseCraft.Accounting.Commands.Accounts.ListAccounts do
            alias PurseCraft.Accounting.Policy
            alias PurseCraft.Accounting.Repositories.AccountRepository

            def call(scope) do
              with :ok <- Policy.authorize(scope, :account, :read) do
                AccountRepository.list()
              end
            end
          end

      ## Allowed

      - Policy modules aliased in Command modules
      - Policy modules aliased in test files
      """
    ]

  alias Credo.SourceFile

  @doc false
  @impl Credo.Check
  def run(%SourceFile{} = source_file, params) do
    issue_meta = IssueMeta.for(source_file, params)

    path = source_file.filename

    if should_check?(path) do
      Credo.Code.prewalk(source_file, &traverse(&1, &2, issue_meta))
    else
      []
    end
  end

  defp should_check?(path) do
    not command_module?(path) and
      not test_file?(path) and
      not policy_module?(path)
  end

  defp command_module?(path) do
    String.contains?(path, "/commands/")
  end

  defp test_file?(path) do
    String.contains?(path, "/test/") or String.starts_with?(path, "test/")
  end

  defp policy_module?(path) do
    String.ends_with?(path, "/policy.ex")
  end

  defp traverse({:alias, meta, [{:__aliases__, _alias_meta, module_path}]} = ast, issues, issue_meta) do
    if policy_module_alias?(module_path) do
      {ast, [issue_for(issue_meta, meta[:line]) | issues]}
    else
      {ast, issues}
    end
  end

  defp traverse(ast, issues, _issue_meta) do
    {ast, issues}
  end

  defp policy_module_alias?(module_path) do
    case List.last(module_path) do
      :Policy -> true
      _other -> false
    end
  end

  defp issue_for(issue_meta, line_no) do
    format_issue(
      issue_meta,
      message: "Policy modules should only be used in Command modules. Move authorization logic to a Command module.",
      line_no: line_no
    )
  end
end

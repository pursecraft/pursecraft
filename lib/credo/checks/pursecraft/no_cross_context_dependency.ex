defmodule Credo.Check.PurseCraft.NoCrossContextDependency do
  @moduledoc false
  use Credo.Check,
    base_priority: :high,
    category: :design,
    explanations: [
      check: """
      Contexts should be independent and not depend on each other directly.

      ## Architecture Pattern

      Business contexts (Accounting, Budgeting, etc.) should be loosely coupled.
      Use PubSub for cross-context communication instead of direct dependencies.

      ## Allowed Dependencies

      - Any context → Core (shared entities)
      - Any context → Identity (user/scope)
      - Any context → PubSub (event broadcasting)
      - Any context → Utilities (helpers)
      - Search → Any context (aggregation layer)
      - Schemas → Any schema (database associations)

      ## Bad Example

          defmodule PurseCraft.Accounting.Commands.SomeCommand do
            alias PurseCraft.Budgeting.Repositories.EnvelopeRepository
          end

      ## Good Example

          defmodule PurseCraft.Accounting.Commands.SomeCommand do
            alias PurseCraft.Accounting.Repositories.AccountRepository
            alias PurseCraft.Core.Schemas.Workspace
            alias PurseCraft.PubSub

            def call(scope, attrs) do
              # Use PubSub to communicate with other contexts
              PubSub.broadcast_account_updated(account)
            end
          end

      ## Schema Exception

          defmodule PurseCraft.Accounting.Schemas.TransactionLine do
            alias PurseCraft.Budgeting.Schemas.Envelope

            schema "transaction_lines" do
              belongs_to :envelope, Envelope
            end
          end

      Schemas are allowed to reference other context schemas for database associations.
      """
    ]

  alias Credo.SourceFile

  @doc false
  @impl Credo.Check
  def run(%SourceFile{} = source_file, params) do
    issue_meta = IssueMeta.for(source_file, params)
    path = source_file.filename

    if excluded?(path) do
      []
    else
      file_context = detect_file_context(path)
      Credo.Code.prewalk(source_file, &traverse(&1, &2, issue_meta, file_context))
    end
  end

  defp excluded?(path) do
    String.contains?(path, "/test/") or
      String.contains?(path, "/schemas/")
  end

  defp detect_file_context(filename) do
    cond do
      String.contains?(filename, "/accounting/") -> :accounting
      String.contains?(filename, "/budgeting/") -> :budgeting
      String.contains?(filename, "/core/") -> :core
      String.contains?(filename, "/search/") -> :search
      String.contains?(filename, "/identity/") -> :identity
      true -> :other
    end
  end

  defp detect_aliased_context([:PurseCraft, context, :Schemas | _rest]) when context in [:Accounting, :Budgeting] do
    context
    |> Atom.to_string()
    |> String.downcase()
    |> then(&String.to_atom("#{&1}_schema"))
  end

  defp detect_aliased_context([:PurseCraft, :Accounting | _rest]), do: :accounting
  defp detect_aliased_context([:PurseCraft, :Budgeting | _rest]), do: :budgeting
  defp detect_aliased_context([:PurseCraft, :Core | _rest]), do: :core
  defp detect_aliased_context([:PurseCraft, :Identity | _rest]), do: :identity
  defp detect_aliased_context([:PurseCraft, :PubSub | _rest]), do: :pub_sub
  defp detect_aliased_context([:PurseCraft, :Utilities | _rest]), do: :utilities
  defp detect_aliased_context([:PurseCraft, :Search | _rest]), do: :search
  defp detect_aliased_context(_other), do: :other

  defp traverse({:alias, meta, [{:__aliases__, _alias_meta, module_path}]} = ast, issues, issue_meta, file_context) do
    aliased_context = detect_aliased_context(module_path)

    if forbidden_dependency?(file_context, aliased_context) do
      {ast, [issue_for(issue_meta, meta[:line], aliased_context) | issues]}
    else
      {ast, issues}
    end
  end

  defp traverse(ast, issues, _issue_meta, _file_context) do
    {ast, issues}
  end

  defp forbidden_dependency?(_from, to) when to in [:core, :identity, :pub_sub, :utilities] do
    false
  end

  defp forbidden_dependency?(:search, _to), do: false
  defp forbidden_dependency?(same, same), do: false
  defp forbidden_dependency?(_from, :other), do: false

  # Allow referencing schemas from other contexts (for domain modeling)
  defp forbidden_dependency?(_from, :accounting_schema), do: false
  defp forbidden_dependency?(_from, :budgeting_schema), do: false

  defp forbidden_dependency?(:accounting, :budgeting), do: true
  defp forbidden_dependency?(:budgeting, :accounting), do: true

  defp forbidden_dependency?(_from, _to), do: false

  defp issue_for(issue_meta, line_no, context) do
    context_name =
      context
      |> Atom.to_string()
      |> String.capitalize()

    format_issue(
      issue_meta,
      message:
        "Do not depend on #{context_name} context from this context. Contexts should be independent. Use PubSub for cross-context communication.",
      line_no: line_no
    )
  end
end

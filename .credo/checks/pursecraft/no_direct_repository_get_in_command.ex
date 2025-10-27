defmodule Credo.Check.PurseCraft.NoDirectRepositoryGetInCommand do
  @moduledoc false
  use Credo.Check,
    base_priority: :high,
    category: :design,
    explanations: [
      check: """
      Command modules should use Fetch commands instead of calling Repository `get_by_*` methods directly.

      ## Architecture Pattern

      Fetching entities should be centralized in dedicated Fetch command modules that handle:
      - Fetching by struct (passthrough with optional reload)
      - Fetching by integer ID (internal database ID)
      - Fetching by external_id (UUID string)
      - Authorization checks
      - Consistent error handling

      This ensures a single source of truth for entity fetching logic.

      ## What This Check Catches

      Commands (except Fetch* commands) calling Repository methods like:
      - `AccountRepository.get_by_id/1`
      - `CategoryRepository.get_by_external_id/2`
      - Any `*Repository.get_by_*/N` pattern

      ## What's Allowed

      - Fetch commands can call Repository methods (they're the abstraction layer)
      - Commands calling `Fetch*.call/3` or `Fetch*.call/4`
      - Commands calling other Repository methods like `list_*`, `create`, `update`, `delete`

      ## Bad Example

          defmodule PurseCraft.Budgeting.Commands.Categories.UpdateCategory do
            def call(scope, workspace, category_id, attrs) do
              # Direct repository call - should use FetchCategory
              with {:ok, category} <- CategoryRepository.get_by_external_id(category_id) do
                CategoryRepository.update(category, attrs)
              end
            end
          end

      ## Good Example

          defmodule PurseCraft.Budgeting.Commands.Categories.UpdateCategory do
            alias PurseCraft.Budgeting.Commands.Categories.FetchCategory
            
            def call(scope, workspace, category_id, attrs) do
              # Using Fetch command - handles ID/external_id/struct
              with {:ok, category} <- FetchCategory.call(scope, workspace, category_id) do
                CategoryRepository.update(category, attrs)
              end
            end
          end

      ## Fetch Command Pattern

          defmodule PurseCraft.Budgeting.Commands.Categories.FetchCategory do
            @spec call(Scope.t(), Workspace.t(), Category.t() | integer() | Ecto.UUID.t(), options()) :: 
              {:ok, Category.t()} | {:error, atom()}
            
            # Struct - return as-is (or reload with preloads)
            def call(scope, workspace, %Category{} = category, opts) do
              with :ok <- Policy.authorize(:category_read, scope, %{workspace: workspace}) do
                {:ok, category}
              end
            end
            
            # Integer - query by internal ID
            def call(scope, workspace, id, opts) when is_integer(id) do
              with :ok <- Policy.authorize(:category_read, scope, %{workspace: workspace}) do
                CategoryRepository.get_by_id(id, opts) |> to_result()
              end
            end
            
            # UUID - query by external_id
            def call(scope, workspace, external_id, opts) when is_binary(external_id) do
              with :ok <- Policy.authorize(:category_read, scope, %{workspace: workspace}) do
                CategoryRepository.get_by_external_id(external_id, opts) |> to_result()
              end
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

    if command_module?(path) and not test_file?(path) and not fetch_command?(path) do
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

  defp fetch_command?(path) do
    basename = Path.basename(path, ".ex")

    String.starts_with?(basename, "fetch_") or String.starts_with?(basename, "get_")
  end

  # Match Repository.get_by_* calls
  defp traverse(
         {{:., _dot_meta, [{:__aliases__, _alias_meta, module_parts}, method_name]}, meta, _args} = ast,
         issues,
         issue_meta
       )
       when is_atom(method_name) do
    if repository_module?(module_parts) and get_by_method?(method_name) do
      module_name =
        module_parts
        |> List.last()
        |> Atom.to_string()

      {ast, [issue_for(issue_meta, meta[:line], module_name, method_name) | issues]}
    else
      {ast, issues}
    end
  end

  defp traverse(ast, issues, _issue_meta) do
    {ast, issues}
  end

  defp repository_module?(module_parts) do
    case List.last(module_parts) do
      atom when is_atom(atom) ->
        atom
        |> Atom.to_string()
        |> String.ends_with?("Repository")

      _other ->
        false
    end
  end

  defp get_by_method?(method_name) do
    method_str = Atom.to_string(method_name)

    String.starts_with?(method_str, "get_by_") and
      not String.contains?(method_str, "_name")
  end

  defp issue_for(issue_meta, line_no, module_name, method_name) do
    entity_name = String.replace(module_name, "Repository", "")

    format_issue(
      issue_meta,
      message:
        "Commands should not call #{module_name}.#{method_name}/N directly. " <>
          "Use Fetch#{entity_name}.call/3-4 instead to centralize fetching logic.",
      line_no: line_no
    )
  end
end

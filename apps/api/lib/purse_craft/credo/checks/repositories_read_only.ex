defmodule PurseCraft.Credo.Checks.RepositoriesReadOnly do
  @moduledoc """
  Ensures Repository modules only contain read functions.
  All mutations must go through Commanded.
  """
  use Credo.Check,
    id: "CR002",
    base_priority: :high,
    explanations: [
      check: """
      Repository modules must only contain read functions (get, get_by, list, list_by, exists).
      All mutations must go through Commanded.

      BAD:
        defmodule PurseCraft.Identity.Repositories.UserRepository do
          def create_user(attrs) do  # Writing not allowed!
          end
        end

      GOOD:
        defmodule PurseCraft.Identity.Repositories.UserRepository do
          def get_by_id(id)  # Reading is fine
        end
      """
    ]

  @allowed_names ~w(get get_by list list_by exists)

  @spec run(Credo.SourceFile.t(), list()) :: list(Credo.Issue.t())
  @doc false
  def run(source_file, params \\ []) do
    issue_meta = IssueMeta.for(source_file, params)

    source_file
    |> Credo.Code.ast()
    |> Macro.postwalk([], fn
      {:defmodule, _, [{:__aliases__, _, module_names}, [do: body]]} = ast, acc ->
        module_name = Module.concat(module_names)

        if repository_module?(module_name) do
          {ast, check_repository_functions(body, issue_meta) ++ acc}
        else
          {ast, acc}
        end

      ast, acc ->
        {ast, acc}
    end)
    |> Enum.reverse()
  end

  defp repository_module?(module) do
    module
    |> Module.split()
    |> List.last()
    |> String.ends_with?("Repository")
  end

  defp check_repository_functions({:__block__, _, defs}, issue_meta) do
    defs
    |> Enum.filter(fn
      {:def, _, [{name, _, _args}, _body]} -> not read_function_name?(name)
      _def -> false
    end)
    |> Enum.map(fn def ->
      name = function_name(def)

      format_issue(issue_meta,
        message: "Repository function `#{name}` must use read-only naming (get, get_by, list, list_by, exists).",
        trigger: to_string(name)
      )
    end)
  end

  defp check_repository_functions(_, _), do: []

  defp read_function_name?(name) do
    name_str = to_string(name)

    Enum.any?(@allowed_names, fn allowed ->
      String.starts_with?(name_str, allowed <> "_") or name_str == allowed
    end)
  end

  defp function_name({:def, _, [{name, _, _}, _]}), do: name
  defp function_name(_), do: :unknown
end

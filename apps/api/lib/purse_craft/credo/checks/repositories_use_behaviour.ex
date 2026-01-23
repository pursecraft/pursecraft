defmodule PurseCraft.Credo.Checks.RepositoriesUseBehaviour do
  @moduledoc """
  Ensures Repository modules use the PurseCraft.Repository behaviour
  and are located in a repositories/ directory.
  """
  use Credo.Check,
    id: "CR004",
    base_priority: :high,
    explanations: [
      check: """
      Repository modules must use the PurseCraft.Repository behaviour
      and be in a repositories/ directory.

      BAD:
        # lib/purse_craft/contexts/identity/user_repo.ex
        defmodule PurseCraft.Identity.Repositories.UserRepository do
          def get_by_id(id)
        end

      GOOD:
        # lib/purse_craft/contexts/identity/repositories/user_repository.ex
        defmodule PurseCraft.Identity.Repositories.UserRepository do
          use PurseCraft.Repository

          def get_by_id(id)
        end
      """
    ]

  @spec run(Credo.SourceFile.t(), list()) :: list(Credo.Issue.t())
  @doc false
  def run(source_file, params \\ []) do
    issue_meta = IssueMeta.for(source_file, params)

    {_, issues} =
      source_file
      |> Credo.Code.ast()
      |> Macro.postwalk([], fn
        {:defmodule, _, [{:__aliases__, _, module_names}, [do: body]]} = ast, acc ->
          module_name = Module.concat(module_names)

          if repository_module?(module_name) do
            {ast, check_repository_rules(source_file, body, issue_meta) ++ acc}
          else
            {ast, acc}
          end

        ast, acc ->
          {ast, acc}
      end)

    Enum.reverse(issues)
  end

  defp repository_module?(module) do
    module
    |> Module.split()
    |> List.last()
    |> String.ends_with?("Repository")
  end

  defp check_repository_rules(source_file, body, issue_meta) do
    behaviour_issue = check_repository_behaviour(body, issue_meta)
    path_issue = check_repository_path(source_file, issue_meta)
    behaviour_issue ++ path_issue
  end

  defp check_repository_behaviour({:__block__, _, contents}, issue_meta) do
    has_repository_behaviour =
      Enum.any?(contents, fn
        {:use, _, [{:__aliases__, _, [:PurseCraft, :Repository]}]} ->
          true

        _ast ->
          false
      end)

    if has_repository_behaviour do
      []
    else
      [
        format_issue(issue_meta,
          message: "Repository modules must use `use PurseCraft.Repository`.",
          trigger: "defmodule"
        )
      ]
    end
  end

  defp check_repository_behaviour(_ast, issue_meta) do
    [
      format_issue(issue_meta,
        message: "Repository modules must use `use PurseCraft.Repository`.",
        trigger: "defmodule"
      )
    ]
  end

  defp check_repository_path(source_file, issue_meta) do
    file_path = source_file.filename

    if String.contains?(file_path, "/repositories/") do
      []
    else
      [
        format_issue(issue_meta,
          message: "Repository modules must be in a repositories/ directory.",
          trigger: "defmodule"
        )
      ]
    end
  end
end

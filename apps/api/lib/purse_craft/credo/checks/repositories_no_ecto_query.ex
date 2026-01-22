defmodule PurseCraft.Credo.Checks.RepositoriesNoEctoQuery do
  @moduledoc """
  Ensures Repository modules do not import Ecto.Query directly.
  All queries must be composed through Query modules.
  """
  use Credo.Check,
    id: "CR001",
    base_priority: :high,
    explanations: [
      check: """
      Repository modules must not import Ecto.Query directly.
      Use Query modules for composing Ecto.Query.

      BAD:
        defmodule PurseCraft.Identity.Repositories.UserRepository do
          import Ecto.Query
          def get_by_email(email) do
            from(u in User, where: u.email == ^email)
          end
        end

      GOOD:
        defmodule PurseCraft.Identity.Repositories.UserRepository do
          alias PurseCraft.Identity.Queries.UserQuery
          def get_by_email(email) do
            UserQuery.by_email(email)
          end
        end
      """
    ]

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
          {ast, check_for_ecto_query_import(body, issue_meta) ++ acc}
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

  defp check_for_ecto_query_import({:__block__, _, contents}, issue_meta) do
    Enum.reduce(contents, [], fn
      {:import, _, [{:__aliases__, _, [:Ecto, :Query]}]}, acc ->
        [
          format_issue(issue_meta,
            message: "Repository modules must not import Ecto.Query directly. Use Query modules instead.",
            trigger: "import Ecto.Query"
          )
          | acc
        ]

      _, acc ->
        acc
    end)
  end

  defp check_for_ecto_query_import(_, _), do: []
end

defmodule PurseCraft.Credo.Checks.QueriesUseBehaviour do
  @moduledoc """
  Ensures Query modules use the PurseCraft.Query behaviour
  and are located in a queries/ directory.
  """
  use Credo.Check,
    id: "CR005",
    base_priority: :high,
    explanations: [
      check: """
      Query modules must use the PurseCraft.Query behaviour
      and be in a queries/ directory.

      BAD:
        # lib/purse_craft/contexts/identity/user_lookup.ex
        defmodule PurseCraft.Identity.Queries.UserQuery do
          import Ecto.Query

          def by_email(email) do
            from(u in User, where: u.email == ^email)
          end
        end

      GOOD:
        # lib/purse_craft/contexts/identity/queries/user_query.ex
        defmodule PurseCraft.Identity.Queries.UserQuery do
          use PurseCraft.Query

          # Ecto.Query is now imported
          def base_query do
            from(u in User)
          end

          def by_email(email) do
            from(u in base_query(), where: u.email == ^email)
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

        if query_module?(module_name) do
          {ast, check_query_rules(source_file, body, issue_meta) ++ acc}
        else
          {ast, acc}
        end

      ast, acc ->
        {ast, acc}
    end)
    |> Enum.reverse()
  end

  defp query_module?(module) do
    module
    |> Module.split()
    |> List.last()
    |> String.ends_with?("Query")
  end

  defp check_query_rules(source_file, body, issue_meta) do
    behaviour_issue = check_query_behaviour(body, issue_meta)
    path_issue = check_query_path(source_file, issue_meta)
    behaviour_issue ++ path_issue
  end

  defp check_query_behaviour({:__block__, _, contents}, issue_meta) do
    has_query_behaviour =
      Enum.any?(contents, fn
        {:attribute, _, {:behaviour, {:__aliases__, _, [:PurseCraft, :Query]}}} ->
          true

        {:attribute, _, {:behaviour, {:__aliases__, _, _}}} ->
          false

        _ast ->
          false
      end)

    if has_query_behaviour do
      []
    else
      [
        format_issue(issue_meta,
          message: "Query modules must use `use PurseCraft.Query`.",
          trigger: "defmodule"
        )
      ]
    end
  end

  defp check_query_behaviour(_ast, issue_meta) do
    [
      format_issue(issue_meta,
        message: "Query modules must use `use PurseCraft.Query`.",
        trigger: "defmodule"
      )
    ]
  end

  defp check_query_path(source_file, issue_meta) do
    file_path = source_file.filename

    if String.contains?(file_path, "/queries/") do
      []
    else
      [
        format_issue(issue_meta,
          message: "Query modules must be in a queries/ directory.",
          trigger: "defmodule"
        )
      ]
    end
  end
end

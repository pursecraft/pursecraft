defmodule PurseCraft.Credo.Checks.ServicesUseBehaviour do
  @moduledoc """
  Ensures Service modules use the PurseCraft.Service behaviour
  and are located in a services/ directory.
  """
  use Credo.Check,
    id: "CR003",
    base_priority: :high,
    explanations: [
      check: """
      Service modules must use the PurseCraft.Service behaviour
      and be in a services/ directory.

      BAD:
        # lib/purse_craft/contexts/identity/authenticate_user.ex
        defmodule PurseCraft.Identity.Services.AuthenticateUser do
          def call(email, password)
        end

      GOOD:
        # lib/purse_craft/contexts/identity/services/authenticate_user.ex
        defmodule PurseCraft.Identity.Services.AuthenticateUser do
          @behaviour PurseCraft.Service

          @impl true
          def call(email, password)
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
      {:defmodule, _meta, [{:__aliases__, _, module_names}, [do: body]]} = ast, acc ->
        module_name = Module.concat(module_names)

        if service_module?(module_name) do
          {ast, check_service_rules(source_file, body, issue_meta) ++ acc}
        else
          {ast, acc}
        end

      ast, acc ->
        {ast, acc}
    end)
    |> Enum.reverse()
  end

  defp service_module?(module) do
    segments = Module.split(module)
    Enum.member?(segments, "Services")
  end

  defp check_service_rules(source_file, body, issue_meta) do
    behaviour_issue = check_service_behaviour(body, issue_meta)
    path_issue = check_service_path(source_file, issue_meta)
    behaviour_issue ++ path_issue
  end

  defp check_service_behaviour({:__block__, _, contents}, issue_meta) do
    has_service_behaviour =
      Enum.any?(contents, fn
        {:attribute, _, {:behaviour, {:__aliases__, _, [:PurseCraft, :Service]}}} ->
          true

        {:attribute, _, {:behaviour, {:__aliases__, _, _}}} ->
          false

        _ast ->
          false
      end)

    if has_service_behaviour do
      []
    else
      [
        format_issue(issue_meta,
          message: "Service modules must use `@behaviour PurseCraft.Service`.",
          trigger: "defmodule"
        )
      ]
    end
  end

  defp check_service_behaviour(_ast, issue_meta) do
    [
      format_issue(issue_meta,
        message: "Service modules must use `@behaviour PurseCraft.Service`.",
        trigger: "defmodule"
      )
    ]
  end

  defp check_service_path(source_file, issue_meta) do
    file_path = source_file.filename

    if String.contains?(file_path, "/services/") do
      []
    else
      [
        format_issue(issue_meta,
          message: "Service modules must be in a services/ directory.",
          trigger: "defmodule"
        )
      ]
    end
  end
end

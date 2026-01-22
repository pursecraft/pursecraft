defmodule PurseCraft.Credo.Checks.ServicesCallFunction do
  @moduledoc """
  Ensures Service modules have a `call` function as their public API
  and are located in a services/ directory.
  """
  use Credo.Check,
    id: "CR003",
    base_priority: :high,
    explanations: [
      check: """
      Service modules must have a `call` function and be in a services/ directory.

      BAD:
        # lib/purse_craft/contexts/identity/authenticate_user.ex
        defmodule PurseCraft.Identity.Services.AuthenticateUser do
          def execute(email, password)  # Wrong function name!
        end

      GOOD:
        # lib/purse_craft/contexts/identity/services/authenticate_user.ex
        defmodule PurseCraft.Identity.Services.AuthenticateUser do
          def call(email, password)  # Correct!
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
      {:defmodule, metadata, [{:__aliases__, _, module_names}, [do: body]]} = ast, acc ->
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
    call_issue = check_call_function(body, issue_meta)
    path_issue = check_service_path(source_file, issue_meta)
    call_issue ++ path_issue
  end

  defp check_call_function({:__block__, _, defs}, issue_meta) do
    has_call =
      Enum.any?(defs, fn
        {:def, _, [{:call, _meta, _args}, _body]} ->
          true

        _def ->
          false
      end)

    if has_call do
      []
    else
      [
        format_issue(issue_meta,
          message: "Service modules must have a `call` function.",
          trigger: "def"
        )
      ]
    end
  end

  defp check_call_function(_ast, issue_meta) do
    [
      format_issue(issue_meta,
        message: "Service modules must have a `call` function.",
        trigger: "def"
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

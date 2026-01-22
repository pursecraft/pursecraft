defmodule PurseCraft.Credo.Checks.ContextDelegatePattern do
  @moduledoc """
  Ensures Context modules only contain defdelegate declarations.
  """
  use Credo.Check,
    id: "CR007",
    base_priority: :high,
    explanations: [
      check: """
      Context modules must only contain defdelegate declarations.
      All functions must be delegated to Service or Repository modules.

      BAD:
        defmodule PurseCraft.Identity do
          def authenticate_user(email, password) do
            # No function implementations allowed!
          end

          def get_user(id) do
            # Even reads must be delegated!
          end
        end

      GOOD:
        defmodule PurseCraft.Identity do
          defdelegate authenticate_by_email_and_password(email, password),
            to: Services.AuthenticateByEmailAndPassword,
            as: :call

          defdelegate get_user_by_id(id),
            to: Repositories.UserRepository,
            as: :get_by_id
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

        if context_module?(module_name) do
          {ast, check_context_functions(body, issue_meta) ++ acc}
        else
          {ast, acc}
        end

      ast, acc ->
        {ast, acc}
    end)
    |> Enum.reverse()
  end

  defp context_module?(module) do
    # Context modules are in the identity namespace but not in subdirectories
    segments = Module.split(module)
    length(segments) == 3 and Enum.at(segments, 1) == "Identity"
  end

  defp check_context_functions({:__block__, _, defs}, issue_meta) do
    defs
    |> Enum.filter(fn
      {:def, _, _args} ->
        true

      _def ->
        false
    end)
    |> Enum.map(fn def ->
      name = function_name(def)

      format_issue(issue_meta,
        message: "Context must use defdelegate for `#{name}` instead of def.",
        trigger: to_string(name)
      )
    end)
  end

  defp check_context_functions(_ast, _issue_meta), do: []

  defp function_name({:def, _, [{name, _, _args}, _body]}), do: name
  defp function_name(_ast), do: :unknown
end

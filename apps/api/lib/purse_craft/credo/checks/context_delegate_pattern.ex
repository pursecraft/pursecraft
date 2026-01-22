defmodule PurseCraft.Credo.Checks.ContextDelegatePattern do
  @moduledoc """
  Ensures Context modules use defdelegate for service operations.
  """
  use Credo.Check,
    id: "CR007",
    base_priority: :normal,
    explanations: [
      check: """
      Context modules should use defdelegate to delegate to Service modules.
      Direct function implementation in Context is for simple reads only.

      BAD:
        defmodule PurseCraft.Identity do
          def authenticate_user(email, password) do
            # Business logic implementation here!
          end
        end

      GOOD:
        defmodule PurseCraft.Identity do
          defdelegate authenticate_by_email_and_password(email, password),
            to: AuthenticateByEmailAndPassword,
            as: :call
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
      {:def, _, [{name, _, _args}, _body]} ->
        not read_function_name?(name)

      _def ->
        false
    end)
    |> Enum.map(fn def ->
      name = function_name(def)

      format_issue(issue_meta,
        message: "Context function `#{name}` should use defdelegate to a Service module.",
        trigger: to_string(name)
      )
    end)
  end

  defp check_context_functions(_ast, _issue_meta), do: []

  defp read_function_name?(name) do
    name_str = to_string(name)

    String.starts_with?(name_str, "get_") or
      String.starts_with?(name_str, "list_") or
      name_str in ~w(get list)
  end

  defp function_name({:def, _, [{name, _, _args}, _body]}), do: name
  defp function_name(_ast), do: :unknown
end

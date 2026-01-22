defmodule PurseCraft.Credo.Checks.EventsVersioned do
  @moduledoc """
  Ensures Event modules have @derive Commanded.Event with version.
  """
  use Credo.Check,
    id: "CR004",
    base_priority: :high,
    explanations: [
      check: """
      Event modules must have @derive Commanded.Event with a version.

      BAD:
        defmodule PurseCraft.Identity.Events.UserRegistered do
          defstruct [:user_uuid, :email]
        end

      GOOD:
        defmodule PurseCraft.Identity.Events.UserRegistered do
          @derive Commanded.Event
          @derive {Commanded.Event, version: 1}
          defstruct [:user_uuid, :email]
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

        if event_module?(module_name) do
          {ast, check_event_derives(body, issue_meta) ++ acc}
        else
          {ast, acc}
        end

      ast, acc ->
        {ast, acc}
    end)
    |> Enum.reverse()
  end

  defp event_module?(module) do
    segments = Module.split(module)
    Enum.member?(segments, "Events")
  end

  defp check_event_derives({:__block__, _, contents}, issue_meta) do
    has_commanded_event =
      Enum.any?(contents, fn
        {:@, _, [{:derive, _, _}]} = ast ->
          has_commanded_event_derive?(ast)

        _ast ->
          false
      end)

    if has_commanded_event do
      check_version_derive(contents, issue_meta)
    else
      [
        format_issue(issue_meta,
          message: "Event modules must have `@derive Commanded.Event` annotation.",
          trigger: "defstruct"
        )
      ]
    end
  end

  defp check_event_derives(_ast, _issue_meta), do: []

  defp has_commanded_event_derive?({:@, _, [{:derive, _, [Commanded.Event]}]}), do: true

  defp has_commanded_event_derive?({:@, _, [{:derive, _, [{:__aliases__, _, [:Commanded, :Event]}]}]}), do: true

  defp has_commanded_event_derive?(_ast), do: false

  defp check_version_derive(contents, issue_meta) do
    has_version =
      Enum.any?(contents, fn
        {:@, _, [{:derive, _, [{:{}, _, [:__aliases__, [Commanded, Event]], [version: _]}]}]} ->
          true

        {:@, _, [{:derive, _, [{{:., _, [{:__aliases__, _, [:Commanded, :Event]}, :version]}, _, _}]}]} ->
          true

        _ast ->
          false
      end)

    if has_version do
      []
    else
      [
        format_issue(issue_meta,
          message: "Event modules must have `@derive {Commanded.Event, version: N}` annotation.",
          trigger: "@derive"
        )
      ]
    end
  end
end

defmodule PurseCraft.Credo.Checks.EventsDeriveJasonEncoder do
  @moduledoc """
  Ensures Event modules have @derive Jason.Encoder for JSON serialization.
  """
  use Credo.Check,
    id: "CR006",
    base_priority: :high,
    explanations: [
      check: """
      Event modules must have @derive Jason.Encoder for JSON serialization.

      BAD:
        defmodule PurseCraft.Identity.Events.UserRegistered do
          defstruct [:user_uuid, :email]
        end

      GOOD:
        defmodule PurseCraft.Identity.Events.UserRegistered do
          @derive Jason.Encoder
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
      {:defmodule, _metadata, [{:__aliases__, _, module_names}, [do: body]]} = ast, acc ->
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
    has_jason_encoder =
      Enum.any?(contents, fn
        {:@, _, [{:derive, _, [{:__aliases__, _, [:Jason, :Encoder]}]}]} ->
          true

        {:@, _, [{:derive, _, [{:__aliases__, _, [:Jason]}]}]} ->
          true

        _ast ->
          false
      end)

    if has_jason_encoder do
      []
    else
      [
        format_issue(issue_meta,
          message: "Event modules must have `@derive Jason.Encoder` for JSON serialization.",
          trigger: "defstruct"
        )
      ]
    end
  end

  defp check_event_derives(_ast, issue_meta) do
    [
      format_issue(issue_meta,
        message: "Event modules must have `@derive Jason.Encoder` for JSON serialization.",
        trigger: "defstruct"
      )
    ]
  end
end

defmodule PurseCraft.Search.Workers.GenerateTokensWorker do
  @moduledoc """
  Background worker for updating search tokens when entity searchable fields change.

  Processes token generation jobs by calling the UpdateTokens command.
  """

  use Oban.Worker, queue: :default

  alias PurseCraft.Core.Commands.Workspaces.FetchWorkspace
  alias PurseCraft.Search.Commands.Token.UpdateTokens

  @type searchable_fields :: %{String.t() => String.t()}

  @spec perform(Oban.Job.t()) :: :ok | {:error, term()}
  def perform(%Oban.Job{
        args: %{
          "workspace_id" => workspace_id,
          "entity_type" => entity_type,
          "entity_id" => entity_id,
          "searchable_fields" => searchable_fields
        }
      }) do
    with {:ok, workspace} <- FetchWorkspace.call(workspace_id),
         {:ok, _tokens} <- UpdateTokens.call(workspace, entity_type, entity_id, searchable_fields) do
      :ok
    end
  end
end

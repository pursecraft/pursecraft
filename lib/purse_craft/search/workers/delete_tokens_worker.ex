defmodule PurseCraft.Search.Workers.DeleteTokensWorker do
  @moduledoc """
  Background worker for deleting search tokens when entities are removed.

  Processes token deletion jobs by calling the DeleteTokens command.
  """

  use Oban.Worker, queue: :default

  alias PurseCraft.Search.Commands.Token.DeleteTokens

  @spec perform(Oban.Job.t()) :: :ok | {:error, term()}
  def perform(%Oban.Job{args: %{"entity_type" => entity_type, "entity_id" => entity_id}}) do
    with {:ok, _count} <- DeleteTokens.call(entity_type, entity_id) do
      :ok
    end
  end
end

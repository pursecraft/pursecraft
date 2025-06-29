defmodule PurseCraft.PubSub.BroadcastWorkspace do
  @moduledoc """
  Command for broadcasting notifications about changes for a specific workspace.
  """

  alias PurseCraft.Core.Schemas.Workspace

  @doc """
  Sends notifications about any changes on the given workspace.

  The broadcasted messages match the pattern:

    * {:updated, %Workspace{}}
    * {:deleted, %Workspace{}}

  ## Examples

      iex> call(workspace, {:updated, workspace})
      :ok

      iex> call(workspace, {:deleted, workspace})
      :ok

  """
  @spec call(Workspace.t(), tuple()) :: :ok | {:error, term()}
  def call(%Workspace{} = workspace, message) do
    Phoenix.PubSub.broadcast(PurseCraft.PubSub, "workspace:#{workspace.external_id}", message)
  end
end

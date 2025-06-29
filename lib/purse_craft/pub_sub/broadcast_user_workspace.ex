defmodule PurseCraft.PubSub.BroadcastUserWorkspace do
  @moduledoc """
  Command for broadcasting notifications about workspace changes for a specific user.
  """

  alias PurseCraft.Identity.Schemas.Scope

  @doc """
  Sends notifications about any workspace changes associated with the scoped user.

  The broadcasted messages match the pattern:

    * {:created, %Workspace{}}
    * {:updated, %Workspace{}}
    * {:deleted, %Workspace{}}

  ## Examples

      iex> call(scope, {:created, workspace})
      :ok

      iex> call(scope, {:updated, workspace})
      :ok

      iex> call(scope, {:deleted, workspace})
      :ok

  """
  @spec call(Scope.t(), tuple()) :: :ok | {:error, term()}
  def call(%Scope{} = scope, message) do
    key = scope.user.id

    Phoenix.PubSub.broadcast(PurseCraft.PubSub, "user:#{key}:workspaces", message)
  end
end

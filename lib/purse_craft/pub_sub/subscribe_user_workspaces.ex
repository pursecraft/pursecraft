defmodule PurseCraft.PubSub.SubscribeUserWorkspaces do
  @moduledoc """
  Command for subscribing to notifications about workspace changes for a specific user.
  """

  alias PurseCraft.Identity.Schemas.Scope

  @doc """
  Subscribes to notifications about any workspace changes associated with the scoped user.

  The broadcasted messages match the pattern:

    * {:created, %Workspace{}}
    * {:updated, %Workspace{}}
    * {:deleted, %Workspace{}}

  ## Examples

      iex> call(scope)
      :ok

  """
  @spec call(Scope.t()) :: :ok | {:error, term()}
  def call(%Scope{} = scope) do
    key = scope.user.id

    Phoenix.PubSub.subscribe(PurseCraft.PubSub, "user:#{key}:workspaces")
  end
end

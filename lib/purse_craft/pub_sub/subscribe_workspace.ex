defmodule PurseCraft.PubSub.SubscribeWorkspace do
  @moduledoc """
  Command for subscribing to notifications about changes for a specific workspace.
  """

  alias PurseCraft.Core.Schemas.Workspace

  @doc """
  Subscribes to notifications about any changes on the given workspace.

  The broadcasted messages match the pattern:

    * {:updated, %Workspace{}}
    * {:deleted, %Workspace{}}

  ## Examples

      iex> call(%Workspace{})
      :ok

  """
  @spec call(Workspace.t()) :: :ok | {:error, term()}
  def call(%Workspace{} = workspace) do
    Phoenix.PubSub.subscribe(PurseCraft.PubSub, "workspace:#{workspace.external_id}")
  end
end

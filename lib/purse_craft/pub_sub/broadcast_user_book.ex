defmodule PurseCraft.PubSub.BroadcastUserBook do
  @moduledoc """
  Command for broadcasting notifications about book changes for a specific user.
  """

  alias PurseCraft.Identity.Schemas.Scope

  @doc """
  Sends notifications about any book changes associated with the scoped user.

  The broadcasted messages match the pattern:

    * {:created, %Book{}}
    * {:updated, %Book{}}
    * {:deleted, %Book{}}

  ## Examples

      iex> call(scope, {:created, book})
      :ok

      iex> call(scope, {:updated, book})
      :ok

      iex> call(scope, {:deleted, book})
      :ok

  """
  @spec call(Scope.t(), tuple()) :: :ok | {:error, term()}
  def call(%Scope{} = scope, message) do
    key = scope.user.id

    Phoenix.PubSub.broadcast(PurseCraft.PubSub, "user:#{key}:books", message)
  end
end

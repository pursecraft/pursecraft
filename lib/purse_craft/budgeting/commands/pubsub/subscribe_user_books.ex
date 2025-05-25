defmodule PurseCraft.Budgeting.Commands.PubSub.SubscribeUserBooks do
  @moduledoc """
  Command for subscribing to notifications about book changes for a specific user.
  """

  alias PurseCraft.Identity.Schemas.Scope

  @doc """
  Subscribes to notifications about any book changes associated with the scoped user.

  The broadcasted messages match the pattern:

    * {:created, %Book{}}
    * {:updated, %Book{}}
    * {:deleted, %Book{}}

  ## Examples

      iex> call(scope)
      :ok

  """
  @spec call(Scope.t()) :: :ok | {:error, term()}
  def call(%Scope{} = scope) do
    key = scope.user.id

    Phoenix.PubSub.subscribe(PurseCraft.PubSub, "user:#{key}:books")
  end
end

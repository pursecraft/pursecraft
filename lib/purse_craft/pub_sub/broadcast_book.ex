defmodule PurseCraft.PubSub.BroadcastBook do
  @moduledoc """
  Command for broadcasting notifications about changes for a specific book.
  """

  alias PurseCraft.Budgeting.Schemas.Book

  @doc """
  Sends notifications about any changes on the given book.

  The broadcasted messages match the pattern:

    * {:updated, %Book{}}
    * {:deleted, %Book{}}

  ## Examples

      iex> call(book, {:updated, book})
      :ok

      iex> call(book, {:deleted, book})
      :ok

  """
  @spec call(Book.t(), tuple()) :: :ok | {:error, term()}
  def call(%Book{} = book, message) do
    Phoenix.PubSub.broadcast(PurseCraft.PubSub, "book:#{book.external_id}", message)
  end
end

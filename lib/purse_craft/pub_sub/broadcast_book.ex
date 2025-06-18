defmodule PurseCraft.PubSub.BroadcastBook do
  @moduledoc """
  Broadcasts notifications about changes for a specific book.
  """

  @doc """
  Sends notifications about any changes on the given book.

  ## Examples

      iex> call(book, {:category_created, category})
      :ok

      iex> call(book, {:account_created, account})
      :ok

  """
  @spec call(struct(), tuple()) :: :ok | {:error, term()}
  def call(book, message) when is_struct(book) do
    Phoenix.PubSub.broadcast(PurseCraft.PubSub, "book:#{book.external_id}", message)
  end
end

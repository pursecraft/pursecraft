defmodule PurseCraft.PubSub.SubscribeBook do
  @moduledoc """
  Command for subscribing to notifications about changes for a specific book.
  """

  alias PurseCraft.Core.Schemas.Book

  @doc """
  Subscribes to notifications about any changes on the given book.

  The broadcasted messages match the pattern:

    * {:updated, %Book{}}
    * {:deleted, %Book{}}

  ## Examples

      iex> call(%Book{})
      :ok

  """
  @spec call(Book.t()) :: :ok | {:error, term()}
  def call(%Book{} = book) do
    Phoenix.PubSub.subscribe(PurseCraft.PubSub, "book:#{book.external_id}")
  end
end

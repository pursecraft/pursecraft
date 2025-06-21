defmodule PurseCraft.PubSub.SubscribeBook do
  @moduledoc """
  Subscribes to notifications about changes for a specific book.
  """

  @doc """
  Subscribes to notifications about any changes on the given book.

  The broadcasted messages match the pattern:

    * {:updated, %Book{}}
    * {:deleted, %Book{}}
    * {:account_created, %Account{}}
    * {:account_updated, %Account{}}
    * {:account_deleted, %Account{}}

  ## Examples

      iex> call(%Book{})
      :ok

  """
  @spec call(struct()) :: :ok | {:error, term()}
  def call(book) when is_struct(book) do
    Phoenix.PubSub.subscribe(PurseCraft.PubSub, "book:#{book.external_id}")
  end
end
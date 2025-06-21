defmodule PurseCraft.PubSub do
  @moduledoc """
  Shared PubSub subscription functions for the application.
  """

  alias PurseCraft.PubSub.SubscribeBook
  alias PurseCraft.PubSub.SubscribeCategory
  alias PurseCraft.PubSub.SubscribeUserBooks

  @doc """
  Subscribes to notifications about changes for a specific book.

  ## Examples

      iex> subscribe_book(book)
      :ok

  """
  @spec subscribe_book(struct()) :: :ok | {:error, term()}
  defdelegate subscribe_book(book), to: SubscribeBook, as: :call

  @doc """
  Subscribes to notifications about changes for a specific user's books.

  ## Examples

      iex> subscribe_user_books(scope)
      :ok

  """
  @spec subscribe_user_books(struct()) :: :ok | {:error, term()}
  defdelegate subscribe_user_books(scope), to: SubscribeUserBooks, as: :call

  @doc """
  Subscribes to notifications about changes for a specific category.

  ## Examples

      iex> subscribe_category(category_external_id)
      :ok

  """
  @spec subscribe_category(String.t()) :: :ok | {:error, term()}
  defdelegate subscribe_category(category_external_id), to: SubscribeCategory, as: :call
end
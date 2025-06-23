defmodule PurseCraft.PubSub do
  @moduledoc """
  The PubSub context for handling notifications and broadcasts.
  """

  alias PurseCraft.Budgeting.Schemas.Book
  alias PurseCraft.Budgeting.Schemas.Category
  alias PurseCraft.Identity.Schemas.Scope
  alias PurseCraft.PubSub.BroadcastBook
  alias PurseCraft.PubSub.BroadcastCategory
  alias PurseCraft.PubSub.BroadcastUserBook
  alias PurseCraft.PubSub.SubscribeBook
  alias PurseCraft.PubSub.SubscribeCategory
  alias PurseCraft.PubSub.SubscribeUserBooks

  @doc """
  Subscribes to notifications about any book changes associated with the scoped user.

  The broadcasted messages match the pattern:

    * {:created, %Book{}}
    * {:updated, %Book{}}
    * {:deleted, %Book{}}

  """
  @spec subscribe_user_books(Scope.t()) :: :ok | {:error, term()}
  defdelegate subscribe_user_books(scope), to: SubscribeUserBooks, as: :call

  @doc """
  Sends notifications about any book changes associated with the scoped user.

  The broadcasted messages match the pattern:

    * {:created, %Book{}}
    * {:updated, %Book{}}
    * {:deleted, %Book{}}

  """
  @spec broadcast_user_book(Scope.t(), tuple()) :: :ok | {:error, term()}
  defdelegate broadcast_user_book(scope, message), to: BroadcastUserBook, as: :call

  @doc """
  Subscribes to notifications about any changes on the given book.

  The broadcasted messages match the pattern:

    * {:updated, %Book{}}
    * {:deleted, %Book{}}

  """
  @spec subscribe_book(Book.t()) :: :ok | {:error, term()}
  defdelegate subscribe_book(book), to: SubscribeBook, as: :call

  @doc """
  Sends notifications about any changes on the given book

  The broadcasted messages match the pattern:

    * {:updated, %Book{}}
    * {:deleted, %Book{}}

  """
  @spec broadcast_book(Book.t(), tuple()) :: :ok | {:error, term()}
  defdelegate broadcast_book(book, message), to: BroadcastBook, as: :call

  @doc """
  Subscribes to notifications about changes for a specific category.

  The broadcasted messages match the pattern:

    * {:envelope_repositioned, %Envelope{}}
    * {:envelope_removed, %Envelope{}}

  """
  @spec subscribe_category(Ecto.UUID.t()) :: :ok | {:error, term()}
  defdelegate subscribe_category(category_external_id), to: SubscribeCategory, as: :call

  @doc """
  Broadcasts a message to all subscribers of a specific category.

  The broadcasted messages match the pattern:

    * {:envelope_repositioned, envelope}
    * {:envelope_removed, envelope}
    * {:envelope_created, envelope}
    * {:envelope_updated, envelope}
    * {:envelope_deleted, envelope}

  """
  @spec broadcast_category(Category.t(), BroadcastCategory.message()) :: :ok | {:error, term()}
  defdelegate broadcast_category(category, message), to: BroadcastCategory, as: :call
end

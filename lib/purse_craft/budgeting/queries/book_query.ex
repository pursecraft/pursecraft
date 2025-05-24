defmodule PurseCraft.Budgeting.Queries.BookQuery do
  @moduledoc """
  Query functions for `Book`.
  """

  import Ecto.Query

  alias PurseCraft.Budgeting.Schemas.Book
  alias PurseCraft.Budgeting.Schemas.BookUser

  @doc """
  Returns a query for books associated with a specific user.

  ## Examples

      iex> by_user(user_id)
      #Ecto.Query<...>

  """
  @spec by_user(integer()) :: Ecto.Query.t()
  def by_user(user_id) do
    Book
    |> join(:inner, [b], bu in BookUser, on: bu.book_id == b.id)
    |> where([_b, bu], bu.user_id == ^user_id)
  end

  @doc """
  Returns a query for finding a book by its external ID.

  ## Examples

      iex> by_external_id("abcd-1234")
      #Ecto.Query<...>

  """
  @spec by_external_id(Ecto.UUID.t()) :: Ecto.Query.t()
  def by_external_id(external_id) do
    from(b in Book, where: b.external_id == ^external_id)
  end

  @doc """
  Returns a query for book users associated with a specific book.

  ## Examples

      iex> book_users_by_book_id(1)
      #Ecto.Query<...>

  """
  @spec book_users_by_book_id(integer()) :: Ecto.Query.t()
  def book_users_by_book_id(book_id) do
    from(bu in BookUser, where: bu.book_id == ^book_id)
  end
end

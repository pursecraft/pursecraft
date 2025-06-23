defmodule PurseCraft.Core.Queries.BookUserQuery do
  @moduledoc """
  Query functions for `BookUser`.
  """

  import Ecto.Query

  alias PurseCraft.Core.Schemas.BookUser

  @doc """
  Returns a query for book users associated with a specific book.

  ## Examples

      iex> by_book_id(1)
      #Ecto.Query<...>

  """
  @spec by_book_id(integer()) :: Ecto.Query.t()
  def by_book_id(book_id) do
    from(bu in BookUser, where: bu.book_id == ^book_id)
  end
end

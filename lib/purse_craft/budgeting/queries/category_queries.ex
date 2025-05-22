defmodule PurseCraft.Budgeting.Queries.CategoryQueries do
  @moduledoc """
  Query functions for `Category`.
  """

  import Ecto.Query

  alias PurseCraft.Budgeting.Schemas.Category

  @doc """
  Returns a query for finding a category by its external ID.

  ## Examples

      iex> by_external_id("abcd-1234")
      #Ecto.Query<...>

      iex> Category |> by_external_id("abcd-1234")
      #Ecto.Query<...>

  """
  @spec by_external_id(Ecto.UUID.t()) :: Ecto.Query.t()
  def by_external_id(external_id) do
    by_external_id(Category, external_id)
  end

  @spec by_external_id(Ecto.Queryable.t(), Ecto.UUID.t()) :: Ecto.Query.t()
  def by_external_id(queryable, external_id) do
    from(c in queryable, where: c.external_id == ^external_id)
  end

  @doc """
  Returns a query for finding categories by book ID.

  ## Examples

      iex> by_book_id(1)
      #Ecto.Query<...>

      iex> Category |> by_book_id(1)
      #Ecto.Query<...>

  """
  # coveralls-ignore-start
  @spec by_book_id(integer()) :: Ecto.Query.t()
  def by_book_id(book_id) do
    by_book_id(Category, book_id)
  end

  # coveralls-ignore-stop

  @spec by_book_id(Ecto.Queryable.t(), integer()) :: Ecto.Query.t()
  def by_book_id(queryable, book_id) do
    from(c in queryable, where: c.book_id == ^book_id)
  end
end

defmodule PurseCraft.Budgeting.Queries.CategoryQuery do
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
  @spec by_book_id(integer()) :: Ecto.Query.t()
  def by_book_id(book_id) do
    by_book_id(Category, book_id)
  end

  @spec by_book_id(Ecto.Queryable.t(), integer()) :: Ecto.Query.t()
  def by_book_id(queryable, book_id) do
    from(c in queryable, where: c.book_id == ^book_id)
  end

  @doc """
  Orders categories by position in ascending order.

  ## Examples

      iex> order_by_position()
      #Ecto.Query<...>

      iex> Category |> by_book_id(1) |> order_by_position()
      #Ecto.Query<...>

  """
  @spec order_by_position() :: Ecto.Query.t()
  def order_by_position do
    order_by_position(Category)
  end

  @spec order_by_position(Ecto.Queryable.t()) :: Ecto.Query.t()
  def order_by_position(queryable) do
    from(c in queryable, order_by: [asc: c.position])
  end

  @doc """
  Limits the query to a specific number of results.

  ## Examples

      iex> limit(1)
      #Ecto.Query<...>

      iex> Category |> by_book_id(1) |> limit(5)
      #Ecto.Query<...>

  """
  @spec limit(integer()) :: Ecto.Query.t()
  def limit(count) do
    from(Category, limit: ^count)
  end

  @spec limit(Ecto.Queryable.t(), integer()) :: Ecto.Query.t()
  def limit(queryable, count) do
    from(queryable, limit: ^count)
  end

  @doc """
  Selects only the position field.

  ## Examples

      iex> select_position()
      #Ecto.Query<...>

      iex> Category |> by_book_id(1) |> select_position()
      #Ecto.Query<...>

  """
  @spec select_position() :: Ecto.Query.t()
  def select_position do
    select_position(Category)
  end

  @spec select_position(Ecto.Queryable.t()) :: Ecto.Query.t()
  def select_position(queryable) do
    from(c in queryable, select: c.position)
  end
end

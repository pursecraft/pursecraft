defmodule PurseCraft.Accounting.Queries.AccountQuery do
  @moduledoc """
  Query functions for `Account`.
  """

  import Ecto.Query

  alias PurseCraft.Accounting.Schemas.Account

  @doc """
  Returns a query for finding accounts by book ID.

  ## Examples

      iex> by_book_id(1)
      #Ecto.Query<...>

      iex> Account |> by_book_id(1)
      #Ecto.Query<...>

  """
  @spec by_book_id(integer()) :: Ecto.Query.t()
  def by_book_id(book_id) do
    by_book_id(Account, book_id)
  end

  @spec by_book_id(Ecto.Queryable.t(), integer()) :: Ecto.Query.t()
  def by_book_id(queryable, book_id) do
    from(a in queryable, where: a.book_id == ^book_id)
  end

  @doc """
  Orders accounts by position in ascending order.

  ## Examples

      iex> order_by_position()
      #Ecto.Query<...>

      iex> Account |> by_book_id(1) |> order_by_position()
      #Ecto.Query<...>

  """
  @spec order_by_position() :: Ecto.Query.t()
  def order_by_position do
    order_by_position(Account)
  end

  @spec order_by_position(Ecto.Queryable.t()) :: Ecto.Query.t()
  def order_by_position(queryable) do
    from(a in queryable, order_by: [asc: a.position])
  end

  @doc """
  Limits the query to a specific number of results.

  ## Examples

      iex> limit(1)
      #Ecto.Query<...>

      iex> Account |> by_book_id(1) |> limit(5)
      #Ecto.Query<...>

  """
  @spec limit(integer()) :: Ecto.Query.t()
  def limit(count) do
    from(Account, limit: ^count)
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

      iex> Account |> by_book_id(1) |> select_position()
      #Ecto.Query<...>

  """
  @spec select_position() :: Ecto.Query.t()
  def select_position do
    select_position(Account)
  end

  @spec select_position(Ecto.Queryable.t()) :: Ecto.Query.t()
  def select_position(queryable) do
    from(a in queryable, select: a.position)
  end

  @doc """
  Returns a query for finding accounts by external ID.

  ## Examples

      iex> by_external_id("uuid-123")
      #Ecto.Query<...>

      iex> Account |> by_external_id("uuid-123")
      #Ecto.Query<...>

  """
  @spec by_external_id(String.t()) :: Ecto.Query.t()
  def by_external_id(external_id) do
    by_external_id(Account, external_id)
  end

  @spec by_external_id(Ecto.Queryable.t(), String.t()) :: Ecto.Query.t()
  def by_external_id(queryable, external_id) do
    from(a in queryable, where: a.external_id == ^external_id)
  end

  @doc """
  Returns a query for finding active (non-closed) accounts.

  ## Examples

      iex> active()
      #Ecto.Query<...>

      iex> Account |> by_book_id(1) |> active()
      #Ecto.Query<...>

  """
  @spec active() :: Ecto.Query.t()
  def active do
    active(Account)
  end

  @spec active(Ecto.Queryable.t()) :: Ecto.Query.t()
  def active(queryable) do
    from(a in queryable, where: is_nil(a.closed_at))
  end

  @doc """
  Returns a query for finding accounts by multiple external IDs.

  ## Examples

      iex> by_external_ids(["id1", "id2"])
      #Ecto.Query<...>

      iex> Account |> by_external_ids(["id1", "id2"])
      #Ecto.Query<...>

  """
  @spec by_external_ids([Ecto.UUID.t()]) :: Ecto.Query.t()
  def by_external_ids(external_ids) do
    by_external_ids(Account, external_ids)
  end

  @spec by_external_ids(Ecto.Queryable.t(), [Ecto.UUID.t()]) :: Ecto.Query.t()
  def by_external_ids(queryable, external_ids) do
    from(a in queryable, where: a.external_id in ^external_ids)
  end
end

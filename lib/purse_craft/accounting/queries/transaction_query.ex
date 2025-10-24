defmodule PurseCraft.Accounting.Queries.TransactionQuery do
  @moduledoc """
  Query functions for `Transaction`.
  """

  import Ecto.Query

  alias PurseCraft.Accounting.Schemas.Transaction

  @doc """
  Returns a query for finding transactions by workspace ID.

  ## Examples

      iex> by_workspace_id(1)
      #Ecto.Query<...>

      iex> Transaction |> by_workspace_id(1)
      #Ecto.Query<...>

  """
  @spec by_workspace_id(integer()) :: Ecto.Query.t()
  def by_workspace_id(workspace_id) do
    by_workspace_id(Transaction, workspace_id)
  end

  @spec by_workspace_id(Ecto.Queryable.t(), integer()) :: Ecto.Query.t()
  def by_workspace_id(queryable, workspace_id) do
    from(t in queryable, where: t.workspace_id == ^workspace_id)
  end

  @doc """
  Returns a query for finding transactions by account ID.

  ## Examples

      iex> by_account_id(1)
      #Ecto.Query<...>

      iex> Transaction |> by_account_id(1)
      #Ecto.Query<...>

  """
  @spec by_account_id(integer()) :: Ecto.Query.t()
  def by_account_id(account_id) do
    by_account_id(Transaction, account_id)
  end

  @spec by_account_id(Ecto.Queryable.t(), integer()) :: Ecto.Query.t()
  def by_account_id(queryable, account_id) do
    from(t in queryable, where: t.account_id == ^account_id)
  end

  @doc """
  Returns a query for finding a transaction by ID.

  ## Examples

      iex> by_id(123)
      #Ecto.Query<...>

      iex> Transaction |> by_id(123)
      #Ecto.Query<...>

  """
  @spec by_id(integer()) :: Ecto.Query.t()
  def by_id(id) do
    by_id(Transaction, id)
  end

  @spec by_id(Ecto.Queryable.t(), integer()) :: Ecto.Query.t()
  def by_id(queryable, id) do
    from(t in queryable, where: t.id == ^id)
  end

  @doc """
  Returns a query for finding a transaction by external ID.

  ## Examples

      iex> by_external_id("transaction-uuid")
      #Ecto.Query<...>

      iex> Transaction |> by_external_id("transaction-uuid")
      #Ecto.Query<...>

  """
  @spec by_external_id(String.t()) :: Ecto.Query.t()
  def by_external_id(external_id) do
    by_external_id(Transaction, external_id)
  end

  @spec by_external_id(Ecto.Queryable.t(), String.t()) :: Ecto.Query.t()
  def by_external_id(queryable, external_id) do
    from(t in queryable, where: t.external_id == ^external_id)
  end

  @doc """
  Returns a query for finding transactions within a date range (inclusive).

  ## Examples

      iex> by_date_range(~D[2025-01-01], ~D[2025-01-31])
      #Ecto.Query<...>

      iex> Transaction |> by_date_range(~D[2025-01-01], ~D[2025-01-31])
      #Ecto.Query<...>

  """
  @spec by_date_range(Date.t(), Date.t()) :: Ecto.Query.t()
  def by_date_range(start_date, end_date) do
    by_date_range(Transaction, start_date, end_date)
  end

  @spec by_date_range(Ecto.Queryable.t(), Date.t(), Date.t()) :: Ecto.Query.t()
  def by_date_range(queryable, start_date, end_date) do
    from(t in queryable, where: t.date >= ^start_date and t.date <= ^end_date)
  end

  @doc """
  Orders transactions by date in descending order, with ID as tie-breaker for stable pagination.

  ## Examples

      iex> order_by_date()
      #Ecto.Query<...>

      iex> Transaction |> by_workspace_id(1) |> order_by_date()
      #Ecto.Query<...>

  """
  @spec order_by_date() :: Ecto.Query.t()
  def order_by_date do
    order_by_date(Transaction)
  end

  @spec order_by_date(Ecto.Queryable.t()) :: Ecto.Query.t()
  def order_by_date(queryable) do
    from(t in queryable, order_by: [desc: t.date, desc: t.id])
  end

  @doc """
  Limits the query to a specific number of results.

  ## Examples

      iex> limit(10)
      #Ecto.Query<...>

      iex> Transaction |> by_workspace_id(1) |> limit(5)
      #Ecto.Query<...>

  """
  @spec limit(integer()) :: Ecto.Query.t()
  def limit(count) do
    from(Transaction, limit: ^count)
  end

  @spec limit(Ecto.Queryable.t(), integer()) :: Ecto.Query.t()
  def limit(queryable, count) do
    from(t in queryable, limit: ^count)
  end
end

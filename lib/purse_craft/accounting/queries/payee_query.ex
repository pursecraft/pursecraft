defmodule PurseCraft.Accounting.Queries.PayeeQuery do
  @moduledoc """
  Query functions for `Payee`.
  """

  import Ecto.Query

  alias PurseCraft.Accounting.Schemas.Payee

  @doc """
  Returns a query for finding payees by workspace ID.

  ## Examples

      iex> by_workspace_id(1)
      #Ecto.Query<...>

      iex> Payee |> by_workspace_id(1)
      #Ecto.Query<...>

  """
  @spec by_workspace_id(integer()) :: Ecto.Query.t()
  def by_workspace_id(workspace_id) do
    by_workspace_id(Payee, workspace_id)
  end

  @spec by_workspace_id(Ecto.Queryable.t(), integer()) :: Ecto.Query.t()
  def by_workspace_id(queryable, workspace_id) do
    from(p in queryable, where: p.workspace_id == ^workspace_id)
  end

  @doc """
  Returns a query for finding payees by external ID.

  ## Examples

      iex> by_external_id("payee-uuid")
      #Ecto.Query<...>

      iex> Payee |> by_external_id("payee-uuid")
      #Ecto.Query<...>

  """
  @spec by_external_id(String.t()) :: Ecto.Query.t()
  def by_external_id(external_id) do
    by_external_id(Payee, external_id)
  end

  @spec by_external_id(Ecto.Queryable.t(), String.t()) :: Ecto.Query.t()
  def by_external_id(queryable, external_id) do
    from(p in queryable, where: p.external_id == ^external_id)
  end

  @doc """
  Returns a query for finding payees by name hash.

  ## Examples

      iex> by_name_hash("hashed_name")
      #Ecto.Query<...>

      iex> Payee |> by_name_hash("hashed_name")
      #Ecto.Query<...>

  """
  @spec by_name_hash(binary()) :: Ecto.Query.t()
  def by_name_hash(name_hash) do
    by_name_hash(Payee, name_hash)
  end

  @spec by_name_hash(Ecto.Queryable.t(), binary()) :: Ecto.Query.t()
  def by_name_hash(queryable, name_hash) do
    from(p in queryable, where: p.name_hash == ^name_hash)
  end

  @doc """
  Orders payees by name in ascending order.

  ## Examples

      iex> order_by_name()
      #Ecto.Query<...>

      iex> Payee |> by_workspace_id(1) |> order_by_name()
      #Ecto.Query<...>

  """
  @spec order_by_name() :: Ecto.Query.t()
  def order_by_name do
    order_by_name(Payee)
  end

  @spec order_by_name(Ecto.Queryable.t()) :: Ecto.Query.t()
  def order_by_name(queryable) do
    from(p in queryable, order_by: [asc: p.name])
  end

  @doc """
  Orders payees by insertion date in descending order (most recent first).

  ## Examples

      iex> order_by_recent()
      #Ecto.Query<...>

      iex> Payee |> by_workspace_id(1) |> order_by_recent()
      #Ecto.Query<...>

  """
  @spec order_by_recent() :: Ecto.Query.t()
  def order_by_recent do
    order_by_recent(Payee)
  end

  @spec order_by_recent(Ecto.Queryable.t()) :: Ecto.Query.t()
  def order_by_recent(queryable) do
    from(p in queryable, order_by: [desc: p.inserted_at])
  end

  @doc """
  Limits the query to a specific number of results.

  ## Examples

      iex> limit(10)
      #Ecto.Query<...>

      iex> Payee |> by_workspace_id(1) |> limit(5)
      #Ecto.Query<...>

  """
  @spec limit(integer()) :: Ecto.Query.t()
  def limit(count) do
    from(Payee, limit: ^count)
  end

  @spec limit(Ecto.Queryable.t(), integer()) :: Ecto.Query.t()
  def limit(queryable, count) do
    from(p in queryable, limit: ^count)
  end
end

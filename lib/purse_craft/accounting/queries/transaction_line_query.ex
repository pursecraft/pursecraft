defmodule PurseCraft.Accounting.Queries.TransactionLineQuery do
  @moduledoc """
  Query functions for `TransactionLine`.
  """

  import Ecto.Query

  alias PurseCraft.Accounting.Schemas.TransactionLine

  @doc """
  Returns a query for finding transaction lines by transaction ID.

  ## Examples

      iex> by_transaction_id(1)
      #Ecto.Query<...>

      iex> TransactionLine |> by_transaction_id(1)
      #Ecto.Query<...>

  """
  @spec by_transaction_id(integer()) :: Ecto.Query.t()
  def by_transaction_id(transaction_id) do
    by_transaction_id(TransactionLine, transaction_id)
  end

  @spec by_transaction_id(Ecto.Queryable.t(), integer()) :: Ecto.Query.t()
  def by_transaction_id(queryable, transaction_id) do
    from(tl in queryable, where: tl.transaction_id == ^transaction_id)
  end

  @doc """
  Returns a query for finding transaction lines by envelope ID.

  ## Examples

      iex> by_envelope_id(1)
      #Ecto.Query<...>

      iex> TransactionLine |> by_envelope_id(1)
      #Ecto.Query<...>

  """
  @spec by_envelope_id(integer()) :: Ecto.Query.t()
  def by_envelope_id(envelope_id) do
    by_envelope_id(TransactionLine, envelope_id)
  end

  @spec by_envelope_id(Ecto.Queryable.t(), integer()) :: Ecto.Query.t()
  def by_envelope_id(queryable, envelope_id) do
    from(tl in queryable, where: tl.envelope_id == ^envelope_id)
  end

  @doc """
  Returns a query for transaction lines that are ready to assign (envelope_id is nil).

  ## Examples

      iex> ready_to_assign_only()
      #Ecto.Query<...>

      iex> TransactionLine |> ready_to_assign_only()
      #Ecto.Query<...>

  """
  @spec ready_to_assign_only() :: Ecto.Query.t()
  def ready_to_assign_only do
    ready_to_assign_only(TransactionLine)
  end

  @spec ready_to_assign_only(Ecto.Queryable.t()) :: Ecto.Query.t()
  def ready_to_assign_only(queryable) do
    from(tl in queryable, where: is_nil(tl.envelope_id))
  end
end

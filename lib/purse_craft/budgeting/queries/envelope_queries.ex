defmodule PurseCraft.Budgeting.Queries.EnvelopeQueries do
  @moduledoc """
  Query functions for `Envelope`.
  """

  import Ecto.Query

  alias PurseCraft.Budgeting.Schemas.Category
  alias PurseCraft.Budgeting.Schemas.Envelope

  @doc """
  Returns a query for finding an envelope by its external ID.

  ## Examples

      iex> by_external_id("abcd-1234")
      #Ecto.Query<...>

      iex> Envelope |> by_external_id("abcd-1234")
      #Ecto.Query<...>

  """
  @spec by_external_id(Ecto.UUID.t()) :: Ecto.Query.t()
  def by_external_id(external_id) do
    by_external_id(Envelope, external_id)
  end

  @spec by_external_id(Ecto.Queryable.t(), Ecto.UUID.t()) :: Ecto.Query.t()
  def by_external_id(queryable, external_id) do
    from(e in queryable, where: e.external_id == ^external_id)
  end

  @doc """
  Returns a query for finding envelopes by book ID (through category relationship).

  ## Examples

      iex> by_book_id(1)
      #Ecto.Query<...>

      iex> Envelope |> by_book_id(1)
      #Ecto.Query<...>

  """
  @spec by_book_id(integer()) :: Ecto.Query.t()
  def by_book_id(book_id) do
    by_book_id(Envelope, book_id)
  end

  @spec by_book_id(Ecto.Queryable.t(), integer()) :: Ecto.Query.t()
  def by_book_id(queryable, book_id) do
    from(e in queryable,
      join: c in Category,
      on: e.category_id == c.id,
      where: c.book_id == ^book_id
    )
  end
end

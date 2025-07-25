defmodule PurseCraft.Budgeting.Queries.EnvelopeQuery do
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
  Returns a query for finding envelopes by workspace ID (through category relationship).

  ## Examples

      iex> by_workspace_id(1)
      #Ecto.Query<...>

      iex> Envelope |> by_workspace_id(1)
      #Ecto.Query<...>

  """
  @spec by_workspace_id(integer()) :: Ecto.Query.t()
  # coveralls-ignore-start
  def by_workspace_id(workspace_id) do
    by_workspace_id(Envelope, workspace_id)
  end

  # coveralls-ignore-stop

  @spec by_workspace_id(Ecto.Queryable.t(), integer()) :: Ecto.Query.t()
  def by_workspace_id(queryable, workspace_id) do
    from(e in queryable,
      join: c in Category,
      on: e.category_id == c.id,
      where: c.workspace_id == ^workspace_id
    )
  end

  @doc """
  Returns a query for finding envelopes by category ID.

  ## Examples

      iex> by_category_id(1)
      #Ecto.Query<...>

      iex> Envelope |> by_category_id(1)
      #Ecto.Query<...>

  """
  @spec by_category_id(integer()) :: Ecto.Query.t()
  def by_category_id(category_id) do
    by_category_id(Envelope, category_id)
  end

  @spec by_category_id(Ecto.Queryable.t(), integer()) :: Ecto.Query.t()
  def by_category_id(queryable, category_id) do
    from(e in queryable, where: e.category_id == ^category_id)
  end

  @doc """
  Returns a query ordered by position in ascending order.

  ## Examples

      iex> order_by_position()
      #Ecto.Query<...>

      iex> Envelope |> order_by_position()
      #Ecto.Query<...>

  """
  @spec order_by_position() :: Ecto.Query.t()
  def order_by_position do
    order_by_position(Envelope)
  end

  @spec order_by_position(Ecto.Queryable.t()) :: Ecto.Query.t()
  def order_by_position(queryable) do
    from(e in queryable, order_by: [asc: e.position])
  end

  @doc """
  Returns a query with a limit.

  ## Examples

      iex> limit(5)
      #Ecto.Query<...>

      iex> Envelope |> limit(5)
      #Ecto.Query<...>

  """
  @spec limit(integer()) :: Ecto.Query.t()
  def limit(count) do
    from(Envelope, limit: ^count)
  end

  @spec limit(Ecto.Queryable.t(), integer()) :: Ecto.Query.t()
  def limit(queryable, count) do
    from(queryable, limit: ^count)
  end

  @doc """
  Returns a query that selects only the position field.

  ## Examples

      iex> select_position()
      #Ecto.Query<...>

      iex> Envelope |> select_position()
      #Ecto.Query<...>

  """
  @spec select_position() :: Ecto.Query.t()
  def select_position do
    select_position(Envelope)
  end

  @spec select_position(Ecto.Queryable.t()) :: Ecto.Query.t()
  def select_position(queryable) do
    from(e in queryable, select: e.position)
  end

  @doc """
  Returns a query for finding envelopes by a list of external IDs.

  ## Examples

      iex> by_external_ids(["id1", "id2", "id3"])
      #Ecto.Query<...>

      iex> Envelope |> by_external_ids(["id1", "id2"])
      #Ecto.Query<...>

  """
  @spec by_external_ids([Ecto.UUID.t()]) :: Ecto.Query.t()
  def by_external_ids(external_ids) do
    by_external_ids(Envelope, external_ids)
  end

  @spec by_external_ids(Ecto.Queryable.t(), [Ecto.UUID.t()]) :: Ecto.Query.t()
  def by_external_ids(queryable, external_ids) do
    from(e in queryable, where: e.external_id in ^external_ids)
  end
end

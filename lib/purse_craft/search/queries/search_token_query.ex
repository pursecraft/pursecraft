defmodule PurseCraft.Search.Queries.SearchTokenQuery do
  @moduledoc """
  Query functions for `SearchToken`.
  """

  import Ecto.Query

  alias PurseCraft.Search.Schemas.SearchToken

  @doc """
  Returns a query for finding search tokens by entity ID.

  ## Examples

      iex> by_entity_id(123)
      #Ecto.Query<...>

      iex> SearchToken |> by_entity_id(123)
      #Ecto.Query<...>

  """
  @spec by_entity_id(integer()) :: Ecto.Query.t()
  def by_entity_id(entity_id) do
    by_entity_id(SearchToken, entity_id)
  end

  @spec by_entity_id(Ecto.Queryable.t(), integer()) :: Ecto.Query.t()
  def by_entity_id(queryable, entity_id) do
    from(t in queryable, where: t.entity_id == ^entity_id)
  end

  @doc """
  Returns a query for finding search tokens by entity type and ID.

  ## Examples

      iex> by_entity("account", 123)
      #Ecto.Query<...>

      iex> SearchToken |> by_entity("account", 123)
      #Ecto.Query<...>

  """
  @spec by_entity(String.t(), integer()) :: Ecto.Query.t()
  def by_entity(entity_type, entity_id) do
    by_entity(SearchToken, entity_type, entity_id)
  end

  @spec by_entity(Ecto.Queryable.t(), String.t(), integer()) :: Ecto.Query.t()
  def by_entity(queryable, entity_type, entity_id) do
    from(t in queryable, where: t.entity_type == ^entity_type and t.entity_id == ^entity_id)
  end

  @doc """
  Returns a query for finding search tokens by entity type.

  ## Examples

      iex> by_entity_type("account")
      #Ecto.Query<...>

      iex> SearchToken |> by_entity_type("account")
      #Ecto.Query<...>

  """
  @spec by_entity_type(String.t()) :: Ecto.Query.t()
  def by_entity_type(entity_type) do
    by_entity_type(SearchToken, entity_type)
  end

  @spec by_entity_type(Ecto.Queryable.t(), String.t()) :: Ecto.Query.t()
  def by_entity_type(queryable, entity_type) do
    from(t in queryable, where: t.entity_type == ^entity_type)
  end

  @doc """
  Returns a query for finding search tokens by a list of entity types.

  ## Examples

      iex> by_entity_types(["account", "category"])
      #Ecto.Query<...>

      iex> SearchToken |> by_entity_types(["account", "category"])
      #Ecto.Query<...>

  """
  @spec by_entity_types(list(String.t())) :: Ecto.Query.t()
  def by_entity_types(entity_types) do
    by_entity_types(SearchToken, entity_types)
  end

  @spec by_entity_types(Ecto.Queryable.t(), list(String.t())) :: Ecto.Query.t()
  def by_entity_types(queryable, entity_types) do
    from(t in queryable, where: t.entity_type in ^entity_types)
  end

  @doc """
  Returns a query for finding search tokens by field name.

  ## Examples

      iex> by_field_name("name")
      #Ecto.Query<...>

      iex> SearchToken |> by_field_name("name")
      #Ecto.Query<...>

  """
  @spec by_field_name(String.t()) :: Ecto.Query.t()
  def by_field_name(field_name) do
    by_field_name(SearchToken, field_name)
  end

  @spec by_field_name(Ecto.Queryable.t(), String.t()) :: Ecto.Query.t()
  def by_field_name(queryable, field_name) do
    from(t in queryable, where: t.field_name == ^field_name)
  end

  @doc """
  Returns a query for finding search tokens by a list of token hashes.

  ## Examples

      iex> by_tokens(["tok", "ken", "has"])
      #Ecto.Query<...>

      iex> SearchToken |> by_tokens(["tok", "ken", "has"])
      #Ecto.Query<...>

  """
  @spec by_tokens(list(String.t())) :: Ecto.Query.t()
  def by_tokens(tokens) do
    by_tokens(SearchToken, tokens)
  end

  @spec by_tokens(Ecto.Queryable.t(), list(String.t())) :: Ecto.Query.t()
  def by_tokens(queryable, tokens) do
    from(t in queryable, where: t.token_hash in ^tokens)
  end

  @doc """
  Returns a query for finding search tokens by workspace ID.

  ## Examples

      iex> by_workspace_id(1)
      #Ecto.Query<...>

      iex> SearchToken |> by_workspace_id(1)
      #Ecto.Query<...>

  """
  @spec by_workspace_id(integer()) :: Ecto.Query.t()
  def by_workspace_id(workspace_id) do
    by_workspace_id(SearchToken, workspace_id)
  end

  @spec by_workspace_id(Ecto.Queryable.t(), integer()) :: Ecto.Query.t()
  def by_workspace_id(queryable, workspace_id) do
    from(t in queryable, where: t.workspace_id == ^workspace_id)
  end

  @doc """
  Groups search tokens by entity type and ID, counting matches.

  ## Examples

      iex> group_by_entity()
      #Ecto.Query<...>

      iex> SearchToken |> by_workspace_id(1) |> group_by_entity()
      #Ecto.Query<...>

  """
  @spec group_by_entity() :: Ecto.Query.t()
  def group_by_entity do
    group_by_entity(SearchToken)
  end

  @spec group_by_entity(Ecto.Queryable.t()) :: Ecto.Query.t()
  def group_by_entity(queryable) do
    from(t in queryable,
      group_by: [t.entity_type, t.entity_id],
      select: %{
        entity_type: t.entity_type,
        entity_id: t.entity_id,
        match_count: count(t.id)
      }
    )
  end

  @doc """
  Limits the query to a specific number of results.

  ## Examples

      iex> limit(10)
      #Ecto.Query<...>

      iex> SearchToken |> by_workspace_id(1) |> limit(5)
      #Ecto.Query<...>

  """
  @spec limit(integer()) :: Ecto.Query.t()
  def limit(limit_count) do
    from(SearchToken, limit: ^limit_count)
  end

  @spec limit(Ecto.Queryable.t(), integer()) :: Ecto.Query.t()
  def limit(queryable, limit_count) do
    from(t in queryable, limit: ^limit_count)
  end

  @doc """
  Orders search tokens by match count in descending order.

  ## Examples

      iex> order_by_match_count()
      #Ecto.Query<...>

      iex> SearchToken |> group_by_entity() |> order_by_match_count()
      #Ecto.Query<...>

  """
  @spec order_by_match_count() :: Ecto.Query.t()
  def order_by_match_count do
    order_by_match_count(SearchToken)
  end

  @spec order_by_match_count(Ecto.Queryable.t()) :: Ecto.Query.t()
  def order_by_match_count(queryable) do
    from(t in queryable, order_by: [desc: count(t.id)])
  end
end

defmodule PurseCraft.Core.Queries.WorkspaceQuery do
  @moduledoc """
  Query functions for `Workspace`.
  """

  import Ecto.Query

  alias PurseCraft.Core.Schemas.Workspace
  alias PurseCraft.Core.Schemas.WorkspaceUser

  @doc """
  Returns a query for finding a workspace by its ID.

  ## Examples

      iex> by_id(123)
      #Ecto.Query<...>

      iex> Workspace |> by_id(123)
      #Ecto.Query<...>

  """
  @spec by_id(integer()) :: Ecto.Query.t()
  def by_id(id) do
    by_id(Workspace, id)
  end

  @spec by_id(Ecto.Queryable.t(), integer()) :: Ecto.Query.t()
  def by_id(queryable, id) do
    from(w in queryable, where: w.id == ^id)
  end

  @doc """
  Returns a query for workspaces associated with a specific user.

  ## Examples

      iex> by_user(user_id)
      #Ecto.Query<...>

  """
  @spec by_user(integer()) :: Ecto.Query.t()
  def by_user(user_id) do
    Workspace
    |> join(:inner, [w], wu in WorkspaceUser, on: wu.workspace_id == w.id)
    |> where([_w, wu], wu.user_id == ^user_id)
  end

  @doc """
  Returns a query for finding a workspace by its external ID.

  ## Examples

      iex> by_external_id("abcd-1234")
      #Ecto.Query<...>

  """
  @spec by_external_id(Ecto.UUID.t()) :: Ecto.Query.t()
  def by_external_id(external_id) do
    from(w in Workspace, where: w.external_id == ^external_id)
  end
end

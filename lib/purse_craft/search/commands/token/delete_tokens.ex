defmodule PurseCraft.Search.Commands.Token.DeleteTokens do
  @moduledoc """
  Deletes all search tokens for a specific entity.

  Used when entities are removed to clean up their associated search tokens.
  """

  alias PurseCraft.Repo
  alias PurseCraft.Search.Queries.SearchTokenQuery

  @doc """
  Deletes all search tokens for the specified entity.

  ## Examples

      iex> DeleteTokens.call("account", 123)
      {:ok, 5}

      iex> DeleteTokens.call("category", 999)
      {:ok, 0}

  """
  @spec call(String.t(), integer()) :: {:ok, non_neg_integer()}
  def call(entity_type, entity_id) do
    {count, _tokens} =
      entity_type
      |> SearchTokenQuery.by_entity(entity_id)
      |> Repo.delete_all()

    {:ok, count}
  end
end

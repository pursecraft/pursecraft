defmodule PurseCraft.Utilities.MaybeLimit do
  @moduledoc """
  Utilities for conditionally applying limit to Ecto queries.
  """

  import Ecto.Query

  @doc """
  Applies a limit to a query if the `:limit` option is provided.

  This is a common pattern where we want to conditionally limit query results
  based on options passed to repository functions. Extracts the `:limit` key
  from the options and applies it to the query.

  ## Examples

      iex> call(query, [])
      #Ecto.Query<...>

      iex> call(query, limit: 10)
      #Ecto.Query<from ... limit: 10>

  """
  @spec call(Ecto.Queryable.t(), keyword()) :: Ecto.Query.t()
  def call(query, opts) when is_list(opts) do
    case Keyword.get(opts, :limit) do
      nil -> query
      count -> from(q in query, limit: ^count)
    end
  end
end

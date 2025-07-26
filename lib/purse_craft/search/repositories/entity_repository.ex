defmodule PurseCraft.Search.Repositories.EntityRepository do
  @moduledoc """
  Repository for loading entities based on search results.
  """

  import Ecto.Query

  alias PurseCraft.Accounting.Schemas.Account
  alias PurseCraft.Budgeting.Schemas.Category
  alias PurseCraft.Budgeting.Schemas.Envelope
  alias PurseCraft.Core.Schemas.Workspace
  alias PurseCraft.Repo

  @type search_token_result :: %{
          entity_type: String.t(),
          entity_id: integer(),
          match_count: integer()
        }

  @type loaded_entity_result :: %{
          entity_type: String.t(),
          entity_id: integer(),
          entity: any(),
          match_count: integer()
        }

  @doc """
  Lists entities by loading them from search token results.

  Takes search token results and loads the actual entity records,
  preserving match count information for relevance ranking.

  ## Examples

      iex> search_results = [
      ...>   %{entity_type: "account", entity_id: 1, match_count: 3},
      ...>   %{entity_type: "category", entity_id: 2, match_count: 2}
      ...> ]
      iex> list_by_search_results(search_results)
      [
        %{entity_type: "account", entity_id: 1, entity: %Account{}, match_count: 3},
        %{entity_type: "category", entity_id: 2, entity: %Category{}, match_count: 2}
      ]

      iex> list_by_search_results([])
      []

  """
  @spec list_by_search_results(list(search_token_result())) :: list(loaded_entity_result())
  def list_by_search_results(search_results) do
    search_results
    |> Enum.group_by(& &1.entity_type)
    |> Enum.flat_map(&load_entities_by_type/1)
  end

  defp load_entities_by_type({"account", results}) do
    entity_ids = Enum.map(results, & &1.entity_id)

    Account
    |> where([a], a.id in ^entity_ids)
    |> Repo.all()
    |> Enum.map(fn entity ->
      result = Enum.find(results, &(&1.entity_id == entity.id))

      %{
        entity_type: "account",
        entity_id: entity.id,
        entity: entity,
        match_count: result.match_count
      }
    end)
  end

  defp load_entities_by_type({"category", results}) do
    entity_ids = Enum.map(results, & &1.entity_id)

    Category
    |> where([c], c.id in ^entity_ids)
    |> Repo.all()
    |> Enum.map(fn entity ->
      result = Enum.find(results, &(&1.entity_id == entity.id))

      %{
        entity_type: "category",
        entity_id: entity.id,
        entity: entity,
        match_count: result.match_count
      }
    end)
  end

  defp load_entities_by_type({"envelope", results}) do
    entity_ids = Enum.map(results, & &1.entity_id)

    Envelope
    |> where([e], e.id in ^entity_ids)
    |> Repo.all()
    |> Enum.map(fn entity ->
      result = Enum.find(results, &(&1.entity_id == entity.id))

      %{
        entity_type: "envelope",
        entity_id: entity.id,
        entity: entity,
        match_count: result.match_count
      }
    end)
  end

  defp load_entities_by_type({"workspace", results}) do
    entity_ids = Enum.map(results, & &1.entity_id)

    Workspace
    |> where([w], w.id in ^entity_ids)
    |> Repo.all()
    |> Enum.map(fn entity ->
      result = Enum.find(results, &(&1.entity_id == entity.id))

      %{
        entity_type: "workspace",
        entity_id: entity.id,
        entity: entity,
        match_count: result.match_count
      }
    end)
  end

  defp load_entities_by_type({unknown_type, results}) do
    # For unknown entity types, we return results with nil entity
    # This allows the relevance calculation to proceed and test the default multiplier
    Enum.map(results, fn result ->
      %{
        entity_type: unknown_type,
        entity_id: result.entity_id,
        entity: nil,
        match_count: result.match_count
      }
    end)
  end
end

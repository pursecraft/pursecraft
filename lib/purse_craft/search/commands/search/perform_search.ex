defmodule PurseCraft.Search.Commands.Search.PerformSearch do
  @moduledoc """
  Performs encrypted search across entities using n-gram tokens.

  Provides workspace-scoped search with relevance ranking.
  """

  alias PurseCraft.Core.Schemas.Workspace
  alias PurseCraft.Repo
  alias PurseCraft.Search.Commands.Ngram.GenerateNgram
  alias PurseCraft.Search.Queries.SearchTokenQuery
  alias PurseCraft.Search.Repositories.EntityRepository
  alias PurseCraft.Search.Schemas.SearchToken

  @min_search_length 3

  @type search_result :: %{
          entity_type: String.t(),
          entity_id: integer(),
          entity: any(),
          match_count: integer(),
          relevance_score: float()
        }

  @type opts :: [
          entity_types: list(String.t()),
          limit: integer()
        ]

  @spec call(Workspace.t(), String.t(), opts()) :: list(search_result())
  def call(workspace, query, opts \\ [])

  def call(workspace, query, opts) when byte_size(query) >= @min_search_length do
    entity_types = Keyword.get(opts, :entity_types, SearchToken.valid_entity_types())
    limit = Keyword.get(opts, :limit, 20)

    search_tokens = GenerateNgram.call(query)

    workspace.id
    |> SearchTokenQuery.by_workspace_id()
    |> SearchTokenQuery.by_entity_types(entity_types)
    |> SearchTokenQuery.by_tokens(search_tokens)
    |> SearchTokenQuery.group_by_entity()
    |> SearchTokenQuery.order_by_match_count()
    |> SearchTokenQuery.limit(limit)
    |> Repo.all()
    |> EntityRepository.list_by_search_results()
    |> rank_results(search_tokens)
  end

  def call(_workspace, _query, _opts), do: []

  defp rank_results(entities, search_tokens) do
    total_tokens = length(search_tokens)

    entities
    |> Enum.map(&calculate_relevance_score(&1, total_tokens))
    |> Enum.sort_by(& &1.relevance_score, :desc)
  end

  defp calculate_relevance_score(entity, total_tokens) do
    # Base score from match count percentage
    match_ratio = entity.match_count / total_tokens

    # Entity type priority (commonly searched entities rank higher)
    type_multiplier =
      case entity.entity_type do
        "account" -> 1.2
        "category" -> 1.1
        "envelope" -> 1.0
        "workspace" -> 0.9
        # coveralls-ignore-next-line
        _entity_type -> 0.8
      end

    relevance_score = match_ratio * type_multiplier

    Map.put(entity, :relevance_score, relevance_score)
  end
end

defmodule PurseCraft.Search.Commands.Token.UpdateTokens do
  @moduledoc """
  Updates search tokens for an entity when its searchable fields change.

  Replaces existing tokens with newly generated ones based on current field values.
  """

  alias Ecto.Multi
  alias PurseCraft.Core.Schemas.Workspace
  alias PurseCraft.Repo
  alias PurseCraft.Search.Commands.Token.GenerateToken
  alias PurseCraft.Search.Queries.SearchTokenQuery
  alias PurseCraft.Search.Schemas.SearchToken

  @type searchable_fields :: %{String.t() => String.t()}

  @spec call(Workspace.t(), String.t(), integer(), searchable_fields()) ::
          {:ok, list(SearchToken.t())} | {:error, term()}
  def call(workspace, entity_type, entity_id, searchable_fields) do
    delete_query =
      workspace.id
      |> SearchTokenQuery.by_workspace_id()
      |> SearchTokenQuery.by_entity(entity_type, entity_id)

    Multi.new()
    |> Multi.delete_all(:delete_existing, delete_query)
    |> Multi.run(:generate_tokens, fn _repo, _changes ->
      tokens = generate_token_data(workspace, entity_type, entity_id, searchable_fields)
      {:ok, tokens}
    end)
    |> Multi.run(:insert_tokens, fn repo, %{generate_tokens: tokens} ->
      case tokens do
        [] ->
          # coveralls-ignore-next-line
          {:ok, []}

        tokens ->
          {_count, inserted} = repo.insert_all(SearchToken, tokens, returning: true)
          {:ok, inserted}
      end
    end)
    |> Repo.transaction()
    |> case do
      {:ok, %{insert_tokens: inserted_tokens}} -> {:ok, inserted_tokens}
      # coveralls-ignore-next-line
      {:error, _step, reason, _changes} -> {:error, reason}
    end
  end

  defp generate_token_data(workspace, entity_type, entity_id, searchable_fields) do
    now = DateTime.utc_now(:second)

    Enum.flat_map(searchable_fields, fn {field_name, value} ->
      value
      |> GenerateToken.call(field_name)
      |> Enum.map(
        &Map.merge(&1, %{
          entity_type: entity_type,
          entity_id: entity_id,
          workspace_id: workspace.id,
          inserted_at: now,
          updated_at: now
        })
      )
    end)
  end
end

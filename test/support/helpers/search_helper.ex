defmodule PurseCraft.TestHelpers.SearchHelper do
  @moduledoc """
  Test helper functions for search-related tests.
  """

  alias PurseCraft.Search.Commands.Ngram.GenerateNgram
  alias PurseCraft.SearchFactory

  @doc """
  Inserts search tokens for an entity based on text content.

  Generates n-grams from the text and creates SearchToken records
  for the specified entity and field.
  """
  def insert_search_tokens_for_entity(workspace, entity_type, entity_id, field_name, text) do
    text
    |> GenerateNgram.call()
    |> Enum.each(fn token ->
      SearchFactory.insert(:search_token,
        workspace: workspace,
        entity_type: entity_type,
        entity_id: entity_id,
        field_name: field_name,
        token_hash: token
      )
    end)
  end
end

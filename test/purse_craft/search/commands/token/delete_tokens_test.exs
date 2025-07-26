defmodule PurseCraft.Search.Commands.Token.DeleteTokensTest do
  use PurseCraft.DataCase, async: true

  alias PurseCraft.CoreFactory
  alias PurseCraft.Repo
  alias PurseCraft.Search.Commands.Token.DeleteTokens
  alias PurseCraft.Search.Schemas.SearchToken
  alias PurseCraft.TestHelpers.SearchHelper

  setup do
    workspace = CoreFactory.insert(:workspace)
    %{workspace: workspace}
  end

  describe "call/2" do
    test "deletes all tokens for specified entity", %{workspace: workspace} do
      # Create search tokens for the target entity
      SearchHelper.insert_search_tokens_for_entity(workspace, "account", 123, "name", "test account")

      # Create search tokens for different entities (should not be deleted)
      SearchHelper.insert_search_tokens_for_entity(workspace, "account", 456, "name", "other account")
      SearchHelper.insert_search_tokens_for_entity(workspace, "category", 123, "name", "test category")

      # Get initial count
      initial_account_123_tokens =
        SearchToken
        |> Repo.all()
        |> Enum.filter(&(&1.entity_type == "account" && &1.entity_id == 123))

      initial_count = length(initial_account_123_tokens)

      assert {:ok, ^initial_count} = DeleteTokens.call("account", 123)

      # Verify only the target entity's tokens were deleted
      remaining_tokens = Repo.all(SearchToken)

      account_456_tokens = Enum.filter(remaining_tokens, &(&1.entity_type == "account" && &1.entity_id == 456))
      category_123_tokens = Enum.filter(remaining_tokens, &(&1.entity_type == "category" && &1.entity_id == 123))
      account_123_tokens = Enum.filter(remaining_tokens, &(&1.entity_type == "account" && &1.entity_id == 123))

      assert length(account_456_tokens) > 0
      assert length(category_123_tokens) > 0
      assert Enum.empty?(account_123_tokens)
    end

    test "returns zero count when no tokens exist for entity" do
      assert {:ok, 0} = DeleteTokens.call("account", 999)
    end

    test "deletes tokens for different entity types", %{workspace: workspace} do
      # Create tokens for category
      SearchHelper.insert_search_tokens_for_entity(workspace, "category", 789, "name", "test category")

      initial_tokens =
        SearchToken
        |> Repo.all()
        |> Enum.filter(&(&1.entity_type == "category" && &1.entity_id == 789))

      initial_count = length(initial_tokens)

      assert {:ok, ^initial_count} = DeleteTokens.call("category", 789)

      remaining_tokens =
        SearchToken
        |> Repo.all()
        |> Enum.filter(&(&1.entity_type == "category" && &1.entity_id == 789))

      assert Enum.empty?(remaining_tokens)
    end

    test "deletes multiple field tokens for same entity", %{workspace: workspace} do
      # Create tokens for multiple fields of the same entity
      SearchHelper.insert_search_tokens_for_entity(workspace, "account", 555, "name", "test account")
      SearchHelper.insert_search_tokens_for_entity(workspace, "account", 555, "description", "account description")

      initial_tokens =
        SearchToken
        |> Repo.all()
        |> Enum.filter(&(&1.entity_type == "account" && &1.entity_id == 555))

      initial_count = length(initial_tokens)

      assert initial_count > 0
      assert {:ok, ^initial_count} = DeleteTokens.call("account", 555)

      remaining_tokens =
        SearchToken
        |> Repo.all()
        |> Enum.filter(&(&1.entity_type == "account" && &1.entity_id == 555))

      assert Enum.empty?(remaining_tokens)
    end
  end
end

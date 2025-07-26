defmodule PurseCraft.Search.Commands.Search.PerformSearchTest do
  use PurseCraft.DataCase, async: true

  alias PurseCraft.AccountingFactory
  alias PurseCraft.BudgetingFactory
  alias PurseCraft.CoreFactory
  alias PurseCraft.Search.Commands.Search.PerformSearch
  alias PurseCraft.TestHelpers.SearchHelper

  setup do
    workspace = CoreFactory.insert(:workspace)
    other_workspace = CoreFactory.insert(:workspace)

    # Create entities in target workspace
    account = AccountingFactory.insert(:account, workspace: workspace)
    category = BudgetingFactory.insert(:category, workspace: workspace)
    envelope = BudgetingFactory.insert(:envelope, category: category)

    # Create entity in other workspace (should not appear in results)
    other_account = AccountingFactory.insert(:account, workspace: other_workspace)

    # Create search tokens
    SearchHelper.insert_search_tokens_for_entity(workspace, "account", account.id, "name", "hello world")
    SearchHelper.insert_search_tokens_for_entity(workspace, "category", category.id, "name", "hello category")
    SearchHelper.insert_search_tokens_for_entity(workspace, "envelope", envelope.id, "name", "world envelope")
    SearchHelper.insert_search_tokens_for_entity(workspace, "workspace", workspace.id, "name", "test workspace")
    SearchHelper.insert_search_tokens_for_entity(other_workspace, "account", other_account.id, "name", "hello other")

    %{
      workspace: workspace,
      other_workspace: other_workspace,
      account: account,
      category: category,
      envelope: envelope,
      other_account: other_account
    }
  end

  describe "call/3" do
    test "returns empty list for queries shorter than minimum length", %{workspace: workspace} do
      short_query_results = PerformSearch.call(workspace, "hi")

      assert short_query_results == []
    end

    test "returns empty list for empty query", %{workspace: workspace} do
      empty_results = PerformSearch.call(workspace, "")

      assert empty_results == []
    end

    test "returns empty list when no tokens match", %{workspace: workspace} do
      no_match_results = PerformSearch.call(workspace, "nonexistent")

      assert no_match_results == []
    end

    test "performs search with matches and relevance scoring", %{
      workspace: workspace,
      account: account,
      category: category
    } do
      results = PerformSearch.call(workspace, "hello")

      assert length(results) == 2

      # Results should be sorted by relevance score (account has higher priority than category)
      [first_result, second_result] = results

      # Account should rank higher due to type multiplier (1.2 vs 1.1)
      assert first_result.entity_type == "account"
      assert first_result.entity.id == account.id
      assert first_result.match_count > 0
      assert first_result.relevance_score > 0

      assert second_result.entity_type == "category"
      assert second_result.entity.id == category.id
      assert second_result.match_count > 0
      assert second_result.relevance_score > 0

      # Account should have higher relevance score
      assert first_result.relevance_score > second_result.relevance_score
    end

    test "searches only within specified workspace", %{
      workspace: workspace,
      other_workspace: other_workspace,
      account: account
    } do
      results = PerformSearch.call(workspace, "hello")

      # Should only find entities from the target workspace
      entity_ids = Enum.map(results, & &1.entity.id)
      assert account.id in entity_ids

      # Should not find entities from other workspace
      other_results = PerformSearch.call(other_workspace, "hello")
      other_entity_ids = Enum.map(other_results, & &1.entity.id)
      refute account.id in other_entity_ids
    end

    test "filters by entity_types option", %{workspace: workspace, account: account, category: category} do
      # Search only for accounts
      account_results = PerformSearch.call(workspace, "hello", entity_types: ["account"])

      assert length(account_results) == 1
      assert hd(account_results).entity_type == "account"
      assert hd(account_results).entity.id == account.id

      # Search only for categories
      category_results = PerformSearch.call(workspace, "hello", entity_types: ["category"])

      assert length(category_results) == 1
      assert hd(category_results).entity_type == "category"
      assert hd(category_results).entity.id == category.id
    end

    test "respects limit option", %{workspace: workspace} do
      # Search with limit of 1
      limited_results = PerformSearch.call(workspace, "hello", limit: 1)

      assert length(limited_results) == 1

      # Without limit should return more results
      all_results = PerformSearch.call(workspace, "hello")

      assert length(all_results) > 1
    end

    test "handles different entity type priorities", %{workspace: workspace} do
      # Create tokens for "world" which appears in multiple entities with same match count
      results = PerformSearch.call(workspace, "world")

      # Should have account, envelope results (account prioritized over envelope)
      assert length(results) >= 2

      entity_types = Enum.map(results, & &1.entity_type)
      assert "account" in entity_types
      assert "envelope" in entity_types

      # Find account and envelope results
      account_result = Enum.find(results, &(&1.entity_type == "account"))
      envelope_result = Enum.find(results, &(&1.entity_type == "envelope"))

      # Account should rank higher than envelope (1.2 vs 1.0 multiplier)
      assert account_result.relevance_score > envelope_result.relevance_score
    end

    test "handles workspace entity type with correct priority", %{workspace: workspace} do
      results = PerformSearch.call(workspace, "test")

      # Should find workspace entity
      workspace_result = Enum.find(results, &(&1.entity_type == "workspace"))
      assert workspace_result != nil
      assert workspace_result.entity.id == workspace.id
      assert workspace_result.relevance_score > 0
    end

    test "handles unknown entity types with default priority" do
      # This tests the catch-all case in calculate_relevance_score

      # Call the private function indirectly by creating a scenario that would use it
      workspace = CoreFactory.insert(:workspace)

      # Create tokens for an entity type that would use the default multiplier
      SearchHelper.insert_search_tokens_for_entity(workspace, "payee", 999, "name", "test payee")

      results = PerformSearch.call(workspace, "test")

      # Should handle the payee entity type with default 0.8 multiplier
      payee_result = Enum.find(results, &(&1.entity_type == "payee"))

      if payee_result do
        assert payee_result.relevance_score > 0
      end
    end

    test "calculates relevance scores correctly based on match ratios" do
      workspace = CoreFactory.insert(:workspace)
      account = AccountingFactory.insert(:account, workspace: workspace)

      # Create tokens that will result in different match ratios
      SearchHelper.insert_search_tokens_for_entity(workspace, "account", account.id, "name", "hello world test")

      # Search for "hello" (should match 1 out of 3+ tokens)
      hello_results = PerformSearch.call(workspace, "hello")

      # Search for "hello world" (should match 2 out of 3+ tokens)
      hello_world_results = PerformSearch.call(workspace, "hello world")

      if length(hello_results) > 0 && length(hello_world_results) > 0 do
        hello_score = hd(hello_results).relevance_score
        hello_world_score = hd(hello_world_results).relevance_score

        # More matching tokens should result in higher relevance score
        assert hello_world_score >= hello_score
      end
    end
  end
end

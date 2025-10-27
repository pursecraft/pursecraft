defmodule PurseCraft.Search.Repositories.EntityRepositoryTest do
  use PurseCraft.DataCase, async: true

  alias PurseCraft.AccountingFactory
  alias PurseCraft.BudgetingFactory
  alias PurseCraft.CoreFactory
  alias PurseCraft.Search.Repositories.EntityRepository

  setup do
    workspace = CoreFactory.insert(:workspace)
    %{workspace: workspace}
  end

  describe "list_by_search_results/1" do
    test "returns empty list for empty input" do
      assert EntityRepository.list_by_search_results([]) == []
    end

    test "loads account entities with match counts", %{workspace: workspace} do
      account1 = AccountingFactory.insert(:account, workspace: workspace)
      account2 = AccountingFactory.insert(:account, workspace: workspace)

      search_results = [
        %{entity_type: "account", entity_id: account1.id, match_count: 3},
        %{entity_type: "account", entity_id: account2.id, match_count: 1}
      ]

      results = EntityRepository.list_by_search_results(search_results)

      assert length(results) == 2

      # Find results by entity ID
      result1 = Enum.find(results, &(&1.entity_id == account1.id))
      result2 = Enum.find(results, &(&1.entity_id == account2.id))

      assert result1.entity_type == "account"
      assert result1.entity.id == account1.id
      assert result1.match_count == 3

      assert result2.entity_type == "account"
      assert result2.entity.id == account2.id
      assert result2.match_count == 1
    end

    test "loads category entities with match counts", %{workspace: workspace} do
      category1 = BudgetingFactory.insert(:category, workspace: workspace, position: "a")
      category2 = BudgetingFactory.insert(:category, workspace: workspace, position: "b")

      search_results = [
        %{entity_type: "category", entity_id: category1.id, match_count: 2},
        %{entity_type: "category", entity_id: category2.id, match_count: 4}
      ]

      results = EntityRepository.list_by_search_results(search_results)

      assert length(results) == 2

      result1 = Enum.find(results, &(&1.entity_id == category1.id))
      result2 = Enum.find(results, &(&1.entity_id == category2.id))

      assert result1.entity_type == "category"
      assert result1.entity.id == category1.id
      assert result1.match_count == 2

      assert result2.entity_type == "category"
      assert result2.entity.id == category2.id
      assert result2.match_count == 4
    end

    test "loads envelope entities with match counts", %{workspace: workspace} do
      category = BudgetingFactory.insert(:category, workspace: workspace)
      envelope1 = BudgetingFactory.insert(:envelope, category: category)
      envelope2 = BudgetingFactory.insert(:envelope, category: category)

      search_results = [
        %{entity_type: "envelope", entity_id: envelope1.id, match_count: 5},
        %{entity_type: "envelope", entity_id: envelope2.id, match_count: 2}
      ]

      results = EntityRepository.list_by_search_results(search_results)

      assert length(results) == 2

      result1 = Enum.find(results, &(&1.entity_id == envelope1.id))
      result2 = Enum.find(results, &(&1.entity_id == envelope2.id))

      assert result1.entity_type == "envelope"
      assert result1.entity.id == envelope1.id
      assert result1.match_count == 5

      assert result2.entity_type == "envelope"
      assert result2.entity.id == envelope2.id
      assert result2.match_count == 2
    end

    test "loads workspace entities with match counts" do
      workspace1 = CoreFactory.insert(:workspace)
      workspace2 = CoreFactory.insert(:workspace)

      search_results = [
        %{entity_type: "workspace", entity_id: workspace1.id, match_count: 1},
        %{entity_type: "workspace", entity_id: workspace2.id, match_count: 3}
      ]

      results = EntityRepository.list_by_search_results(search_results)

      assert length(results) == 2

      result1 = Enum.find(results, &(&1.entity_id == workspace1.id))
      result2 = Enum.find(results, &(&1.entity_id == workspace2.id))

      assert result1.entity_type == "workspace"
      assert result1.entity.id == workspace1.id
      assert result1.match_count == 1

      assert result2.entity_type == "workspace"
      assert result2.entity.id == workspace2.id
      assert result2.match_count == 3
    end

    test "loads mixed entity types with match counts", %{workspace: workspace} do
      account = AccountingFactory.insert(:account, workspace: workspace)
      category = BudgetingFactory.insert(:category, workspace: workspace, position: "c")
      envelope = BudgetingFactory.insert(:envelope, category: category)

      search_results = [
        %{entity_type: "account", entity_id: account.id, match_count: 2},
        %{entity_type: "category", entity_id: category.id, match_count: 4},
        %{entity_type: "envelope", entity_id: envelope.id, match_count: 1}
      ]

      results = EntityRepository.list_by_search_results(search_results)

      assert length(results) == 3

      account_result = Enum.find(results, &(&1.entity_type == "account"))
      category_result = Enum.find(results, &(&1.entity_type == "category"))
      envelope_result = Enum.find(results, &(&1.entity_type == "envelope"))

      assert account_result.entity.id == account.id
      assert account_result.match_count == 2

      assert category_result.entity.id == category.id
      assert category_result.match_count == 4

      assert envelope_result.entity.id == envelope.id
      assert envelope_result.match_count == 1
    end

    test "handles unknown entity types with nil entity" do
      search_results = [
        %{entity_type: "unknown", entity_id: 123, match_count: 5},
        %{entity_type: "invalid", entity_id: 456, match_count: 2}
      ]

      results = EntityRepository.list_by_search_results(search_results)

      assert length(results) == 2

      unknown_result = Enum.find(results, &(&1.entity_type == "unknown"))
      assert unknown_result.entity_id == 123
      assert unknown_result.entity == nil
      assert unknown_result.match_count == 5

      invalid_result = Enum.find(results, &(&1.entity_type == "invalid"))
      assert invalid_result.entity_id == 456
      assert invalid_result.entity == nil
      assert invalid_result.match_count == 2
    end

    test "handles mixed known and unknown entity types", %{workspace: workspace} do
      account = AccountingFactory.insert(:account, workspace: workspace)

      search_results = [
        %{entity_type: "account", entity_id: account.id, match_count: 3},
        %{entity_type: "unknown", entity_id: 999, match_count: 1},
        %{entity_type: "invalid", entity_id: 888, match_count: 2}
      ]

      results = EntityRepository.list_by_search_results(search_results)

      assert length(results) == 3

      account_result = Enum.find(results, &(&1.entity_type == "account"))
      assert account_result.entity.id == account.id
      assert account_result.match_count == 3

      unknown_result = Enum.find(results, &(&1.entity_type == "unknown"))
      assert unknown_result.entity == nil
      assert unknown_result.match_count == 1

      invalid_result = Enum.find(results, &(&1.entity_type == "invalid"))
      assert invalid_result.entity == nil
      assert invalid_result.match_count == 2
    end

    test "handles entities that don't exist in database", %{workspace: workspace} do
      account = AccountingFactory.insert(:account, workspace: workspace)

      search_results = [
        %{entity_type: "account", entity_id: account.id, match_count: 2},
        # Non-existent ID
        %{entity_type: "account", entity_id: 99_999, match_count: 1}
      ]

      results = EntityRepository.list_by_search_results(search_results)

      # Only the existing account should be returned
      assert length(results) == 1

      result = hd(results)
      assert result.entity_type == "account"
      assert result.entity.id == account.id
      assert result.match_count == 2
    end
  end
end

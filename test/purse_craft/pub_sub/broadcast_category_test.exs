defmodule PurseCraft.PubSub.BroadcastCategoryTest do
  use PurseCraft.DataCase, async: true

  alias Phoenix.PubSub
  alias PurseCraft.BudgetingFactory
  alias PurseCraft.PubSub.BroadcastCategory

  describe "call/2" do
    test "broadcasts envelope_repositioned message to category channel" do
      book = BudgetingFactory.insert(:book)
      category = BudgetingFactory.insert(:category, book: book)
      envelope = BudgetingFactory.insert(:envelope, category: category)

      PubSub.subscribe(PurseCraft.PubSub, "category:#{category.external_id}")

      assert :ok = BroadcastCategory.call(category, {:envelope_repositioned, envelope})
      assert_receive {:envelope_repositioned, ^envelope}
    end

    test "broadcasts envelope_removed message to category channel" do
      book = BudgetingFactory.insert(:book)
      category = BudgetingFactory.insert(:category, book: book)
      envelope = BudgetingFactory.insert(:envelope, category: category)

      PubSub.subscribe(PurseCraft.PubSub, "category:#{category.external_id}")

      assert :ok = BroadcastCategory.call(category, {:envelope_removed, envelope})
      assert_receive {:envelope_removed, ^envelope}
    end

    test "broadcasts envelope_created message to category channel" do
      book = BudgetingFactory.insert(:book)
      category = BudgetingFactory.insert(:category, book: book)
      envelope = BudgetingFactory.insert(:envelope, category: category)

      PubSub.subscribe(PurseCraft.PubSub, "category:#{category.external_id}")

      assert :ok = BroadcastCategory.call(category, {:envelope_created, envelope})
      assert_receive {:envelope_created, ^envelope}
    end

    test "broadcasts envelope_updated message to category channel" do
      book = BudgetingFactory.insert(:book)
      category = BudgetingFactory.insert(:category, book: book)
      envelope = BudgetingFactory.insert(:envelope, category: category)

      PubSub.subscribe(PurseCraft.PubSub, "category:#{category.external_id}")

      assert :ok = BroadcastCategory.call(category, {:envelope_updated, envelope})
      assert_receive {:envelope_updated, ^envelope}
    end

    test "broadcasts envelope_deleted message to category channel" do
      book = BudgetingFactory.insert(:book)
      category = BudgetingFactory.insert(:category, book: book)
      envelope = BudgetingFactory.insert(:envelope, category: category)

      PubSub.subscribe(PurseCraft.PubSub, "category:#{category.external_id}")

      assert :ok = BroadcastCategory.call(category, {:envelope_deleted, envelope})
      assert_receive {:envelope_deleted, ^envelope}
    end
  end
end

defmodule PurseCraft.PubSub.BroadcastBookTest do
  use PurseCraft.DataCase, async: true

  alias PurseCraft.BudgetingFactory
  alias PurseCraft.PubSub.BroadcastBook

  describe "call/2" do
    test "broadcasts message to book PubSub channel" do
      book = BudgetingFactory.build(:book, external_id: "test-book-id")

      Phoenix.PubSub.subscribe(PurseCraft.PubSub, "book:test-book-id")

      message = {:test_message, "data"}
      assert :ok = BroadcastBook.call(book, message)

      assert_receive {:test_message, "data"}
    end
  end
end

defmodule PurseCraft.PubSub.SubscribeBookTest do
  use PurseCraft.DataCase, async: true

  alias PurseCraft.BudgetingFactory
  alias PurseCraft.PubSub.SubscribeBook

  describe "call/1" do
    test "subscribes to book PubSub channel" do
      book = BudgetingFactory.build(:book, external_id: "book-123")

      assert :ok = SubscribeBook.call(book)

      Phoenix.PubSub.broadcast(PurseCraft.PubSub, "book:book-123", {:test_message, "data"})

      assert_receive {:test_message, "data"}
    end
  end
end

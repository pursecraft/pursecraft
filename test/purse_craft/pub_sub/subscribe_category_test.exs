defmodule PurseCraft.PubSub.SubscribeCategoryTest do
  use PurseCraft.DataCase, async: true

  alias PurseCraft.PubSub.SubscribeCategory

  describe "call/1" do
    test "subscribes to category PubSub channel" do
      category_external_id = "category-123"

      assert :ok = SubscribeCategory.call(category_external_id)

      Phoenix.PubSub.broadcast(PurseCraft.PubSub, "category:category-123", {:test_message, "data"})

      assert_receive {:test_message, "data"}
    end
  end
end

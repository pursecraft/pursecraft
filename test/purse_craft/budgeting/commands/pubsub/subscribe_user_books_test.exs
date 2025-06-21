defmodule PurseCraft.Budgeting.Commands.PubSub.SubscribeUserBooksTest do
  use PurseCraft.DataCase, async: true

  alias PurseCraft.PubSub.SubscribeUserBooks
  alias PurseCraft.Identity.Schemas.Scope
  alias PurseCraft.IdentityFactory

  describe "call/1" do
    test "subscribes to user books PubSub channel" do
      user = IdentityFactory.build(:user, id: 123)
      scope = %Scope{user: user}

      assert :ok = SubscribeUserBooks.call(scope)

      Phoenix.PubSub.broadcast(PurseCraft.PubSub, "user:123:books", {:test_message, "data"})

      assert_receive {:test_message, "data"}
    end
  end
end

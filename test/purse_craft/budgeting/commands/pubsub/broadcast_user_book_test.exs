defmodule PurseCraft.Budgeting.Commands.PubSub.BroadcastUserBookTest do
  use PurseCraft.DataCase, async: true

  alias PurseCraft.Budgeting.Commands.PubSub.BroadcastUserBook
  alias PurseCraft.Identity.Schemas.Scope
  alias PurseCraft.IdentityFactory

  describe "call/2" do
    test "broadcasts message to user books PubSub channel" do
      user = IdentityFactory.build(:user, id: 123)
      scope = %Scope{user: user}

      Phoenix.PubSub.subscribe(PurseCraft.PubSub, "user:123:books")

      message = {:test_message, "data"}
      assert :ok = BroadcastUserBook.call(scope, message)

      assert_receive {:test_message, "data"}
    end
  end
end

defmodule PurseCraft.PubSub.SubscribeUserWorkspacesTest do
  use PurseCraft.DataCase, async: true

  alias PurseCraft.Identity.Schemas.Scope
  alias PurseCraft.IdentityFactory
  alias PurseCraft.PubSub.SubscribeUserWorkspaces

  describe "call/1" do
    test "subscribes to user workspaces PubSub channel" do
      user = IdentityFactory.build(:user, id: 123)
      scope = %Scope{user: user}

      assert :ok = SubscribeUserWorkspaces.call(scope)

      Phoenix.PubSub.broadcast(PurseCraft.PubSub, "user:123:workspaces", {:test_message, "data"})

      assert_receive {:test_message, "data"}
    end
  end
end

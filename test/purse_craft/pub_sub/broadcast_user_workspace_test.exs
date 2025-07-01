defmodule PurseCraft.PubSub.BroadcastUserWorkspaceTest do
  use PurseCraft.DataCase, async: true

  alias PurseCraft.Identity.Schemas.Scope
  alias PurseCraft.IdentityFactory
  alias PurseCraft.PubSub.BroadcastUserWorkspace

  describe "call/2" do
    test "broadcasts message to user workspaces PubSub channel" do
      user = IdentityFactory.build(:user, id: 123)
      scope = %Scope{user: user}

      Phoenix.PubSub.subscribe(PurseCraft.PubSub, "user:123:workspaces")

      message = {:test_message, "data"}
      assert :ok = BroadcastUserWorkspace.call(scope, message)

      assert_receive {:test_message, "data"}
    end
  end
end

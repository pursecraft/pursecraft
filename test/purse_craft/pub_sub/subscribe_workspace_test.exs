defmodule PurseCraft.PubSub.SubscribeWorkspaceTest do
  use PurseCraft.DataCase, async: true

  alias PurseCraft.CoreFactory
  alias PurseCraft.PubSub.SubscribeWorkspace

  describe "call/1" do
    test "subscribes to workspace PubSub channel" do
      workspace = CoreFactory.build(:workspace, external_id: "workspace-123")

      assert :ok = SubscribeWorkspace.call(workspace)

      Phoenix.PubSub.broadcast(PurseCraft.PubSub, "workspace:workspace-123", {:test_message, "data"})

      assert_receive {:test_message, "data"}
    end
  end
end

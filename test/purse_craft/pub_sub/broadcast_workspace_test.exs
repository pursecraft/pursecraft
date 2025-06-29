defmodule PurseCraft.PubSub.BroadcastWorkspaceTest do
  use PurseCraft.DataCase, async: true

  alias PurseCraft.CoreFactory
  alias PurseCraft.PubSub.BroadcastWorkspace

  describe "call/2" do
    test "broadcasts message to workspace PubSub channel" do
      workspace = CoreFactory.build(:workspace, external_id: "test-workspace-id")

      Phoenix.PubSub.subscribe(PurseCraft.PubSub, "workspace:test-workspace-id")

      message = {:test_message, "data"}
      assert :ok = BroadcastWorkspace.call(workspace, message)

      assert_receive {:test_message, "data"}
    end
  end
end

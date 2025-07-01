defmodule PurseCraft.Core.Commands.Workspaces.ChangeWorkspaceTest do
  use PurseCraft.DataCase, async: true

  alias PurseCraft.Core.Commands.Workspaces.ChangeWorkspace
  alias PurseCraft.CoreFactory

  describe "call/2" do
    test "returns a workspace changeset" do
      workspace = CoreFactory.insert(:workspace)

      assert %Ecto.Changeset{} = changeset = ChangeWorkspace.call(workspace, %{})
      assert changeset.data == workspace
      assert changeset.changes == %{}
    end

    test "returns a workspace changeset with changes" do
      workspace = CoreFactory.insert(:workspace)
      new_name = "New Workspace Name"

      assert %Ecto.Changeset{} = changeset = ChangeWorkspace.call(workspace, %{name: new_name})
      assert changeset.data == workspace
      assert changeset.changes == %{name: new_name, name_hash: new_name}
    end
  end
end

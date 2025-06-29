defmodule PurseCraft.Core.Commands.Workspaces.UpdateWorkspaceTest do
  use PurseCraft.DataCase, async: true

  import Mimic

  alias PurseCraft.Core.Commands.Workspaces.UpdateWorkspace
  alias PurseCraft.Core.Schemas.Workspace
  alias PurseCraft.CoreFactory
  alias PurseCraft.IdentityFactory
  alias PurseCraft.PubSub.BroadcastUserWorkspace
  alias PurseCraft.PubSub.BroadcastWorkspace

  setup do
    user = IdentityFactory.insert(:user)
    workspace = CoreFactory.insert(:workspace)
    CoreFactory.insert(:workspace_user, workspace_id: workspace.id, user_id: user.id, role: :owner)
    scope = IdentityFactory.build(:scope, user: user)

    %{
      user: user,
      scope: scope,
      workspace: workspace
    }
  end

  describe "call/3" do
    test "with valid data updates the workspace", %{scope: scope, workspace: workspace} do
      attrs = %{name: "Updated Workspace Name"}

      assert {:ok, %Workspace{} = updated_workspace} = UpdateWorkspace.call(scope, workspace, attrs)
      assert updated_workspace.name == "Updated Workspace Name"
    end

    test "with invalid data returns error changeset", %{scope: scope, workspace: workspace} do
      attrs = %{name: ""}

      assert {:error, changeset} = UpdateWorkspace.call(scope, workspace, attrs)
      assert %{name: ["can't be blank"]} = errors_on(changeset)
    end

    test "with non-owner role returns unauthorized error", %{workspace: workspace} do
      user = IdentityFactory.insert(:user)
      CoreFactory.insert(:workspace_user, workspace_id: workspace.id, user_id: user.id, role: :editor)
      scope = IdentityFactory.build(:scope, user: user)

      attrs = %{name: "Editor Updated Name"}

      assert {:error, :unauthorized} = UpdateWorkspace.call(scope, workspace, attrs)
    end

    test "with no association to workspace returns unauthorized error", %{workspace: workspace} do
      user = IdentityFactory.insert(:user)
      scope = IdentityFactory.build(:scope, user: user)

      attrs = %{name: "Unauthorized Update"}

      assert {:error, :unauthorized} = UpdateWorkspace.call(scope, workspace, attrs)
    end

    test "broadcasts events when workspace is updated successfully", %{scope: scope, workspace: workspace} do
      expect(BroadcastUserWorkspace, :call, fn broadcast_scope, {:updated, broadcast_workspace} ->
        assert broadcast_scope == scope
        assert broadcast_workspace.id == workspace.id
        assert broadcast_workspace.name == "Broadcasted Workspace Name"
        :ok
      end)

      expect(BroadcastWorkspace, :call, fn broadcast_workspace, {:updated, updated_workspace} ->
        assert broadcast_workspace.id == workspace.id
        assert updated_workspace.id == workspace.id
        assert updated_workspace.name == "Broadcasted Workspace Name"
        :ok
      end)

      attrs = %{name: "Broadcasted Workspace Name"}

      assert {:ok, %Workspace{}} = UpdateWorkspace.call(scope, workspace, attrs)

      verify!()
    end
  end
end

defmodule PurseCraft.Core.Commands.Workspaces.DeleteWorkspaceTest do
  use PurseCraft.DataCase, async: true

  import Mimic

  alias PurseCraft.Core.Commands.Workspaces.DeleteWorkspace
  alias PurseCraft.Core.Schemas.Workspace
  alias PurseCraft.CoreFactory
  alias PurseCraft.IdentityFactory
  alias PurseCraft.PubSub.BroadcastUserWorkspace
  alias PurseCraft.PubSub.BroadcastWorkspace
  alias PurseCraft.Repo

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

  describe "call/2" do
    test "deletes the workspace successfully", %{scope: scope, workspace: workspace} do
      assert {:ok, %Workspace{}} = DeleteWorkspace.call(scope, workspace)
      assert Repo.get(Workspace, workspace.id) == nil
    end

    test "with non-owner role returns unauthorized error", %{workspace: workspace} do
      user = IdentityFactory.insert(:user)
      CoreFactory.insert(:workspace_user, workspace_id: workspace.id, user_id: user.id, role: :editor)
      scope = IdentityFactory.build(:scope, user: user)

      assert {:error, :unauthorized} = DeleteWorkspace.call(scope, workspace)
      assert Repo.get(Workspace, workspace.id) != nil
    end

    test "with no association to workspace returns unauthorized error", %{workspace: workspace} do
      user = IdentityFactory.insert(:user)
      scope = IdentityFactory.build(:scope, user: user)

      assert {:error, :unauthorized} = DeleteWorkspace.call(scope, workspace)
      assert Repo.get(Workspace, workspace.id) != nil
    end

    test "broadcasts events when workspace is deleted successfully", %{scope: scope, workspace: workspace} do
      expect(BroadcastUserWorkspace, :call, fn broadcast_scope, {:deleted, broadcast_workspace} ->
        assert broadcast_scope == scope
        assert broadcast_workspace.id == workspace.id
        :ok
      end)

      expect(BroadcastWorkspace, :call, fn broadcast_workspace, {:deleted, deleted_workspace} ->
        assert broadcast_workspace.id == workspace.id
        assert deleted_workspace.id == workspace.id
        :ok
      end)

      assert {:ok, %Workspace{}} = DeleteWorkspace.call(scope, workspace)

      verify!()
    end
  end
end

defmodule PurseCraft.Core.Commands.Workspaces.ListWorkspacesTest do
  use PurseCraft.DataCase, async: true

  alias PurseCraft.Core.Commands.Workspaces.ListWorkspaces
  alias PurseCraft.CoreFactory
  alias PurseCraft.IdentityFactory

  describe "call/1" do
    test "with associated workspaces returns all scoped workspaces" do
      user = IdentityFactory.insert(:user)
      scope = IdentityFactory.build(:scope, user: user)
      workspace = CoreFactory.insert(:workspace)
      CoreFactory.insert(:workspace_user, workspace_id: workspace.id, user_id: user.id, role: :owner)

      other_user = IdentityFactory.insert(:user)
      other_scope = IdentityFactory.build(:scope, user: other_user)
      other_workspace = CoreFactory.insert(:workspace)
      CoreFactory.insert(:workspace_user, workspace_id: other_workspace.id, user_id: other_user.id)

      result = ListWorkspaces.call(scope)
      assert [returned_workspace] = result
      assert returned_workspace.id == workspace.id
      assert returned_workspace.external_id == workspace.external_id
      assert returned_workspace.name == workspace.name

      other_result = ListWorkspaces.call(other_scope)
      assert [returned_other_workspace] = other_result
      assert returned_other_workspace.id == other_workspace.id
      assert returned_other_workspace.external_id == other_workspace.external_id
      assert returned_other_workspace.name == other_workspace.name
    end

    test "with no associated workspaces returns empty list" do
      user = IdentityFactory.insert(:user)
      scope = IdentityFactory.build(:scope, user: user)

      assert ListWorkspaces.call(scope) == []
    end
  end
end

defmodule PurseCraft.Core.Commands.Workspaces.FetchWorkspaceTest do
  use PurseCraft.DataCase, async: true
  use Mimic

  alias PurseCraft.BudgetingFactory
  alias PurseCraft.Core.Commands.Workspaces.FetchWorkspace
  alias PurseCraft.Core.Policy
  alias PurseCraft.CoreFactory
  alias PurseCraft.IdentityFactory

  describe "call/2" do
    test "with existing workspace returns ok tuple with workspace" do
      workspace = CoreFactory.insert(:workspace)

      assert {:ok, returned_workspace} = FetchWorkspace.call(workspace.id)
      assert returned_workspace.id == workspace.id
    end

    test "supports preloading associations" do
      workspace = CoreFactory.insert(:workspace)
      category1 = BudgetingFactory.insert(:category, workspace_id: workspace.id)
      category2 = BudgetingFactory.insert(:category, workspace_id: workspace.id)

      assert {:ok, workspace_with_preloads} = FetchWorkspace.call(workspace.id, preload: [:categories])

      assert Enum.count(workspace_with_preloads.categories) == 2
      assert Enum.any?(workspace_with_preloads.categories, &(&1.id == category1.id))
      assert Enum.any?(workspace_with_preloads.categories, &(&1.id == category2.id))
    end

    test "with non-existent workspace returns error tuple" do
      assert {:error, :not_found} = FetchWorkspace.call(999_999)
    end
  end

  describe "call/3" do
    test "with associated workspace (authorized scope) returns ok tuple with workspace" do
      user = IdentityFactory.insert(:user)
      scope = IdentityFactory.build(:scope, user: user)
      workspace = CoreFactory.insert(:workspace)
      CoreFactory.insert(:workspace_user, workspace_id: workspace.id, user_id: user.id, role: :owner)

      assert {:ok, returned_workspace} = FetchWorkspace.call(workspace.id, [], scope)
      assert returned_workspace.id == workspace.id
    end

    test "supports preloading associations with authorized scope" do
      user = IdentityFactory.insert(:user)
      scope = IdentityFactory.build(:scope, user: user)
      workspace = CoreFactory.insert(:workspace)
      CoreFactory.insert(:workspace_user, workspace_id: workspace.id, user_id: user.id, role: :owner)

      category1 = BudgetingFactory.insert(:category, workspace_id: workspace.id)
      category2 = BudgetingFactory.insert(:category, workspace_id: workspace.id)

      assert {:ok, workspace_with_preloads} =
               FetchWorkspace.call(workspace.id, [preload: [:categories]], scope)

      assert Enum.count(workspace_with_preloads.categories) == 2
      assert Enum.any?(workspace_with_preloads.categories, &(&1.id == category1.id))
      assert Enum.any?(workspace_with_preloads.categories, &(&1.id == category2.id))
    end

    test "with non-existent workspace returns error tuple" do
      user = IdentityFactory.insert(:user)
      scope = IdentityFactory.build(:scope, user: user)

      expect(Policy, :authorize, fn :workspace_read, _scope, _params -> :ok end)

      assert {:error, :not_found} = FetchWorkspace.call(999_999, [], scope)
    end

    test "with unauthorized scope returns error tuple" do
      user = IdentityFactory.insert(:user)
      scope = IdentityFactory.build(:scope, user: user)
      workspace = CoreFactory.insert(:workspace)

      assert {:error, :unauthorized} = FetchWorkspace.call(workspace.id, [], scope)
    end
  end
end

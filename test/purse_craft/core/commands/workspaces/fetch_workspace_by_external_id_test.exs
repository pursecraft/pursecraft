defmodule PurseCraft.Core.Commands.Workspaces.FetchWorkspaceByExternalIdTest do
  use PurseCraft.DataCase, async: true
  use Mimic

  alias PurseCraft.BudgetingFactory
  alias PurseCraft.Core.Commands.Workspaces.FetchWorkspaceByExternalId
  alias PurseCraft.Core.Policy
  alias PurseCraft.CoreFactory
  alias PurseCraft.IdentityFactory

  describe "call/3" do
    test "with associated workspace (authorized scope) returns ok tuple with workspace" do
      user = IdentityFactory.insert(:user)
      scope = IdentityFactory.build(:scope, user: user)
      workspace = CoreFactory.insert(:workspace)
      CoreFactory.insert(:workspace_user, workspace_id: workspace.id, user_id: user.id, role: :owner)

      assert {:ok, returned_workspace} = FetchWorkspaceByExternalId.call(scope, workspace.external_id)
      assert returned_workspace.id == workspace.id
    end

    test "supports preloading associations" do
      user = IdentityFactory.insert(:user)
      scope = IdentityFactory.build(:scope, user: user)
      workspace = CoreFactory.insert(:workspace)
      CoreFactory.insert(:workspace_user, workspace_id: workspace.id, user_id: user.id, role: :owner)

      category1 = BudgetingFactory.insert(:category, workspace_id: workspace.id, position: "g")
      category2 = BudgetingFactory.insert(:category, workspace_id: workspace.id, position: "m")

      assert {:ok, workspace_with_preloads} =
               FetchWorkspaceByExternalId.call(scope, workspace.external_id, preload: [:categories])

      assert Enum.count(workspace_with_preloads.categories) == 2
      assert Enum.any?(workspace_with_preloads.categories, &(&1.id == category1.id))
      assert Enum.any?(workspace_with_preloads.categories, &(&1.id == category2.id))
    end

    test "with non-existent workspace returns error tuple" do
      user = IdentityFactory.insert(:user)
      scope = IdentityFactory.build(:scope, user: user)
      non_existent_id = Ecto.UUID.generate()

      expect(Policy, :authorize, fn :workspace_read, _scope, _params -> :ok end)

      assert {:error, :not_found} = FetchWorkspaceByExternalId.call(scope, non_existent_id)
    end

    test "with unauthorized scope returns error tuple" do
      user = IdentityFactory.insert(:user)
      scope = IdentityFactory.build(:scope, user: user)
      workspace = CoreFactory.insert(:workspace)

      assert {:error, :unauthorized} = FetchWorkspaceByExternalId.call(scope, workspace.external_id)
    end
  end
end

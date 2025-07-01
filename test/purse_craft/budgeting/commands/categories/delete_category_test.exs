defmodule PurseCraft.Budgeting.Commands.Categories.DeleteCategoryTest do
  use PurseCraft.DataCase, async: true

  import Mimic

  alias PurseCraft.Budgeting.Commands.Categories.DeleteCategory
  alias PurseCraft.Budgeting.Schemas.Category
  alias PurseCraft.BudgetingFactory
  alias PurseCraft.CoreFactory
  alias PurseCraft.IdentityFactory
  alias PurseCraft.PubSub.BroadcastWorkspace

  setup do
    user = IdentityFactory.insert(:user)
    workspace = CoreFactory.insert(:workspace)
    category = BudgetingFactory.insert(:category, workspace: workspace)
    scope = IdentityFactory.build(:scope, user: user)

    {:ok, user: user, workspace: workspace, category: category, scope: scope}
  end

  describe "call/3" do
    test "with owner role (authorized scope) deletes a category", %{
      user: user,
      scope: scope,
      workspace: workspace,
      category: category
    } do
      CoreFactory.insert(:workspace_user, workspace_id: workspace.id, user_id: user.id, role: :owner)

      assert {:ok, deleted_category} = DeleteCategory.call(scope, workspace, category)
      assert deleted_category.id == category.id
      assert_raise Ecto.NoResultsError, fn -> Repo.get!(Category, category.id) end
    end

    test "with editor role (authorized scope) deletes a category", %{workspace: workspace, category: category} do
      user = IdentityFactory.insert(:user)
      CoreFactory.insert(:workspace_user, workspace_id: workspace.id, user_id: user.id, role: :editor)
      scope = IdentityFactory.build(:scope, user: user)

      assert {:ok, deleted_category} = DeleteCategory.call(scope, workspace, category)
      assert deleted_category.id == category.id
      assert_raise Ecto.NoResultsError, fn -> Repo.get!(Category, category.id) end
    end

    test "with commenter role (unauthorized scope) returns error", %{workspace: workspace, category: category} do
      user = IdentityFactory.insert(:user)
      CoreFactory.insert(:workspace_user, workspace_id: workspace.id, user_id: user.id, role: :commenter)
      scope = IdentityFactory.build(:scope, user: user)

      assert {:error, :unauthorized} = DeleteCategory.call(scope, workspace, category)
      assert Repo.get(Category, category.id)
    end

    test "with no association to workspace (unauthorized scope) returns error", %{
      workspace: workspace,
      category: category
    } do
      user = IdentityFactory.insert(:user)
      scope = IdentityFactory.build(:scope, user: user)

      assert {:error, :unauthorized} = DeleteCategory.call(scope, workspace, category)
      assert Repo.get(Category, category.id)
    end

    test "broadcasts category_deleted event when category is deleted successfully", %{
      user: user,
      scope: scope,
      workspace: workspace,
      category: category
    } do
      CoreFactory.insert(:workspace_user, workspace_id: workspace.id, user_id: user.id, role: :owner)

      expect(BroadcastWorkspace, :call, fn broadcast_workspace, {:category_deleted, broadcast_category} ->
        assert broadcast_workspace.id == workspace.id
        assert broadcast_category.id == category.id
        :ok
      end)

      assert {:ok, deleted_category} = DeleteCategory.call(scope, workspace, category)
      assert deleted_category.id == category.id

      verify!()
    end
  end
end

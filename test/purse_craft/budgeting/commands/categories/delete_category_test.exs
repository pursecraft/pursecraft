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
    workspace = CoreFactory.insert(:workspace)
    category = BudgetingFactory.insert(:category, workspace_id: workspace.id)

    %{
      workspace: workspace,
      category: category
    }
  end

  describe "call/3" do
    test "with owner role (authorized scope) deletes a category", %{workspace: workspace, category: category} do
      user = IdentityFactory.insert(:user)
      CoreFactory.insert(:workspace_user, workspace_id: workspace.id, user_id: user.id, role: :owner)
      scope = IdentityFactory.build(:scope, user: user)

      assert {:ok, %Category{}} = DeleteCategory.call(scope, workspace, category)
      assert_raise Ecto.NoResultsError, fn -> Repo.get!(Category, category.id) end
    end

    test "with editor role (authorized scope) deletes a category", %{workspace: workspace, category: category} do
      user = IdentityFactory.insert(:user)
      CoreFactory.insert(:workspace_user, workspace_id: workspace.id, user_id: user.id, role: :editor)
      scope = IdentityFactory.build(:scope, user: user)

      assert {:ok, %Category{}} = DeleteCategory.call(scope, workspace, category)
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

    test "invokes BroadcastWorkspace when category is deleted successfully", %{workspace: workspace, category: category} do
      user = IdentityFactory.insert(:user)
      CoreFactory.insert(:workspace_user, workspace_id: workspace.id, user_id: user.id, role: :owner)
      scope = IdentityFactory.build(:scope, user: user)

      expect(BroadcastWorkspace, :call, fn broadcast_workspace, {:category_deleted, broadcast_category} ->
        assert broadcast_workspace == workspace
        assert broadcast_category.id == category.id
        :ok
      end)

      assert {:ok, %Category{}} = DeleteCategory.call(scope, workspace, category)

      verify!()
    end
  end
end

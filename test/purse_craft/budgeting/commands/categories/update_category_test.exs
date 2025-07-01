defmodule PurseCraft.Budgeting.Commands.Categories.UpdateCategoryTest do
  use PurseCraft.DataCase, async: true

  import Mimic

  alias PurseCraft.Budgeting.Commands.Categories.UpdateCategory
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

  describe "call/4" do
    test "with owner role (authorized scope) updates category successfully", %{
      user: user,
      scope: scope,
      workspace: workspace,
      category: category
    } do
      CoreFactory.insert(:workspace_user, workspace_id: workspace.id, user_id: user.id, role: :owner)
      attrs = %{name: "Updated Category Name"}

      assert {:ok, updated_category} = UpdateCategory.call(scope, workspace, category, attrs)
      assert updated_category.name == "Updated Category Name"
      assert updated_category.id == category.id
    end

    test "with editor role (authorized scope) updates category successfully", %{workspace: workspace, category: category} do
      user = IdentityFactory.insert(:user)
      CoreFactory.insert(:workspace_user, workspace_id: workspace.id, user_id: user.id, role: :editor)
      scope = IdentityFactory.build(:scope, user: user)
      attrs = %{name: "Editor Updated Category"}

      assert {:ok, updated_category} = UpdateCategory.call(scope, workspace, category, attrs)
      assert updated_category.name == "Editor Updated Category"
    end

    test "with commenter role (unauthorized scope) returns error", %{workspace: workspace, category: category} do
      user = IdentityFactory.insert(:user)
      CoreFactory.insert(:workspace_user, workspace_id: workspace.id, user_id: user.id, role: :commenter)
      scope = IdentityFactory.build(:scope, user: user)
      attrs = %{name: "Commenter Category"}

      assert {:error, :unauthorized} = UpdateCategory.call(scope, workspace, category, attrs)
    end

    test "with no association to workspace (unauthorized scope) returns error", %{
      workspace: workspace,
      category: category
    } do
      user = IdentityFactory.insert(:user)
      scope = IdentityFactory.build(:scope, user: user)
      attrs = %{name: "Unauthorized Category"}

      assert {:error, :unauthorized} = UpdateCategory.call(scope, workspace, category, attrs)
    end

    test "with invalid attributes returns changeset error", %{
      user: user,
      scope: scope,
      workspace: workspace,
      category: category
    } do
      CoreFactory.insert(:workspace_user, workspace_id: workspace.id, user_id: user.id, role: :owner)
      attrs = %{name: ""}

      assert {:error, changeset} = UpdateCategory.call(scope, workspace, category, attrs)
      assert %{name: ["can't be blank"]} = errors_on(changeset)
    end

    test "with string keys in attrs updates category correctly", %{
      user: user,
      scope: scope,
      workspace: workspace,
      category: category
    } do
      CoreFactory.insert(:workspace_user, workspace_id: workspace.id, user_id: user.id, role: :owner)
      attrs = %{"name" => "String Key Updated"}

      assert {:ok, updated_category} = UpdateCategory.call(scope, workspace, category, attrs)
      assert updated_category.name == "String Key Updated"
    end

    test "broadcasts category_updated event when category is updated successfully", %{
      user: user,
      scope: scope,
      workspace: workspace,
      category: category
    } do
      CoreFactory.insert(:workspace_user, workspace_id: workspace.id, user_id: user.id, role: :owner)

      expect(BroadcastWorkspace, :call, fn received_workspace, {:category_updated, received_category} ->
        assert received_workspace.id == workspace.id
        assert received_category.name == "Broadcast Test Category"
        :ok
      end)

      attrs = %{name: "Broadcast Test Category"}

      assert {:ok, updated_category} = UpdateCategory.call(scope, workspace, category, attrs)
      assert updated_category.name == "Broadcast Test Category"

      verify!()
    end
  end
end

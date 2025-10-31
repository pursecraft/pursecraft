defmodule PurseCraft.Budgeting.Commands.Categories.ListCategoriesTest do
  use PurseCraft.DataCase, async: true

  alias PurseCraft.Budgeting.Commands.Categories.ListCategories
  alias PurseCraft.BudgetingFactory
  alias PurseCraft.CoreFactory
  alias PurseCraft.IdentityFactory

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
    setup %{workspace: workspace} do
      categories =
        Enum.map(1..3, fn _ -> BudgetingFactory.insert(:category, workspace_id: workspace.id) end)

      other_workspace = CoreFactory.insert(:workspace)
      other_category = BudgetingFactory.insert(:category, workspace_id: other_workspace.id)

      %{categories: categories, other_workspace: other_workspace, other_category: other_category}
    end

    test "with associated workspace (authorized scope) returns all workspace categories", %{
      scope: scope,
      workspace: workspace,
      categories: categories
    } do
      result = ListCategories.call(scope, workspace)

      sorted_result = Enum.sort_by(result, & &1.id)
      sorted_categories = Enum.sort_by(categories, & &1.id)

      assert length(sorted_result) == length(sorted_categories)

      sorted_result
      |> Enum.zip(sorted_categories)
      |> Enum.each(fn {result_cat, expected_cat} ->
        assert result_cat.id == expected_cat.id
        assert result_cat.name == expected_cat.name
        assert result_cat.external_id == expected_cat.external_id
        assert result_cat.workspace_id == workspace.id
      end)
    end

    test "with associated workspace and preload option returns categories with associations", %{
      scope: scope,
      workspace: workspace,
      categories: categories
    } do
      category = List.first(categories)
      envelope = BudgetingFactory.insert(:envelope, category_id: category.id)

      result = ListCategories.call(scope, workspace, preload: [:envelopes])

      category_with_envelope = Enum.find(result, fn cat -> cat.id == category.id end)
      assert [loaded_envelope] = category_with_envelope.envelopes
      assert loaded_envelope.id == envelope.id
      assert loaded_envelope.name == envelope.name

      other_categories = Enum.filter(result, fn cat -> cat.id != category.id end)

      Enum.each(other_categories, fn cat ->
        assert cat.envelopes == []
      end)
    end

    test "with editor role (authorized scope) returns categories", %{
      workspace: workspace,
      categories: categories
    } do
      user = IdentityFactory.insert(:user)
      CoreFactory.insert(:workspace_user, workspace_id: workspace.id, user_id: user.id, role: :editor)
      scope = IdentityFactory.build(:scope, user: user)

      result = ListCategories.call(scope, workspace)
      assert length(result) == length(categories)
    end

    test "with commenter role (authorized scope) returns categories", %{
      workspace: workspace,
      categories: categories
    } do
      user = IdentityFactory.insert(:user)
      CoreFactory.insert(:workspace_user, workspace_id: workspace.id, user_id: user.id, role: :commenter)
      scope = IdentityFactory.build(:scope, user: user)

      result = ListCategories.call(scope, workspace)
      assert length(result) == length(categories)
    end

    test "with no association to workspace (unauthorized scope) returns error", %{
      workspace: workspace
    } do
      user = IdentityFactory.insert(:user)
      scope = IdentityFactory.build(:scope, user: user)

      assert {:error, :unauthorized} = ListCategories.call(scope, workspace)
    end

    test "returns only categories for the specified workspace", %{
      scope: scope,
      workspace: workspace,
      categories: categories,
      other_workspace: other_workspace,
      other_category: other_category
    } do
      CoreFactory.insert(:workspace_user, workspace_id: other_workspace.id, user_id: scope.user.id, role: :owner)

      workspace_categories = ListCategories.call(scope, workspace)
      assert length(workspace_categories) == length(categories)
      assert Enum.all?(workspace_categories, fn cat -> cat.workspace_id == workspace.id end)

      other_workspace_categories = ListCategories.call(scope, other_workspace)
      assert length(other_workspace_categories) == 1
      assert hd(other_workspace_categories).id == other_category.id
    end
  end
end

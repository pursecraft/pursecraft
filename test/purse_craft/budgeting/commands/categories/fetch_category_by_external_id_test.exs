defmodule PurseCraft.Budgeting.Commands.Categories.FetchCategoryByExternalIdTest do
  use PurseCraft.DataCase, async: true

  alias PurseCraft.Budgeting.Commands.Categories.FetchCategoryByExternalId
  alias PurseCraft.Budgeting.Schemas.Category
  alias PurseCraft.BudgetingFactory
  alias PurseCraft.CoreFactory
  alias PurseCraft.IdentityFactory

  setup do
    workspace = CoreFactory.insert(:workspace)
    category = BudgetingFactory.insert(:category, workspace_id: workspace.id)

    %{
      workspace: workspace,
      category: category
    }
  end

  describe "call/4" do
    test "with valid external_id returns category", %{workspace: workspace, category: category} do
      user = IdentityFactory.insert(:user)
      CoreFactory.insert(:workspace_user, workspace_id: workspace.id, user_id: user.id, role: :owner)
      scope = IdentityFactory.build(:scope, user: user)

      assert {:ok, %Category{} = fetched_category} =
               FetchCategoryByExternalId.call(scope, workspace, category.external_id)

      assert fetched_category.id == category.id
      assert fetched_category.name == category.name
    end

    test "with valid external_id and preload option returns category with preloaded associations", %{
      workspace: workspace,
      category: category
    } do
      user = IdentityFactory.insert(:user)
      CoreFactory.insert(:workspace_user, workspace_id: workspace.id, user_id: user.id, role: :owner)
      scope = IdentityFactory.build(:scope, user: user)

      envelope = BudgetingFactory.insert(:envelope, category_id: category.id)

      assert {:ok, %Category{} = fetched_category} =
               FetchCategoryByExternalId.call(scope, workspace, category.external_id, preload: [:envelopes])

      assert fetched_category.id == category.id
      assert length(fetched_category.envelopes) == 1
      assert hd(fetched_category.envelopes).id == envelope.id
    end

    test "with invalid external_id returns not found error", %{workspace: workspace} do
      user = IdentityFactory.insert(:user)
      CoreFactory.insert(:workspace_user, workspace_id: workspace.id, user_id: user.id, role: :owner)
      scope = IdentityFactory.build(:scope, user: user)

      assert {:error, :not_found} = FetchCategoryByExternalId.call(scope, workspace, Ecto.UUID.generate())
    end

    test "with owner role (authorized scope) returns category", %{workspace: workspace, category: category} do
      user = IdentityFactory.insert(:user)
      CoreFactory.insert(:workspace_user, workspace_id: workspace.id, user_id: user.id, role: :owner)
      scope = IdentityFactory.build(:scope, user: user)

      assert {:ok, %Category{}} = FetchCategoryByExternalId.call(scope, workspace, category.external_id)
    end

    test "with editor role (authorized scope) returns category", %{workspace: workspace, category: category} do
      user = IdentityFactory.insert(:user)
      CoreFactory.insert(:workspace_user, workspace_id: workspace.id, user_id: user.id, role: :editor)
      scope = IdentityFactory.build(:scope, user: user)

      assert {:ok, %Category{}} = FetchCategoryByExternalId.call(scope, workspace, category.external_id)
    end

    test "with commenter role (authorized scope) returns category", %{workspace: workspace, category: category} do
      user = IdentityFactory.insert(:user)
      CoreFactory.insert(:workspace_user, workspace_id: workspace.id, user_id: user.id, role: :commenter)
      scope = IdentityFactory.build(:scope, user: user)

      assert {:ok, %Category{}} = FetchCategoryByExternalId.call(scope, workspace, category.external_id)
    end

    test "with no association to workspace (unauthorized scope) returns error", %{
      workspace: workspace,
      category: category
    } do
      user = IdentityFactory.insert(:user)
      scope = IdentityFactory.build(:scope, user: user)

      assert {:error, :unauthorized} = FetchCategoryByExternalId.call(scope, workspace, category.external_id)
    end

    test "with category from different workspace returns not found", %{category: category} do
      different_workspace = CoreFactory.insert(:workspace)
      user = IdentityFactory.insert(:user)
      CoreFactory.insert(:workspace_user, workspace_id: different_workspace.id, user_id: user.id, role: :owner)
      scope = IdentityFactory.build(:scope, user: user)

      assert {:error, :not_found} = FetchCategoryByExternalId.call(scope, different_workspace, category.external_id)
    end
  end
end

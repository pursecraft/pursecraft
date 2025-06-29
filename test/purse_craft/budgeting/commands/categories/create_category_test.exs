defmodule PurseCraft.Budgeting.Commands.Categories.CreateCategoryTest do
  use PurseCraft.DataCase, async: true

  import Mimic

  alias PurseCraft.Budgeting.Commands.Categories.CreateCategory
  alias PurseCraft.Budgeting.Schemas.Category
  alias PurseCraft.BudgetingFactory
  alias PurseCraft.CoreFactory
  alias PurseCraft.IdentityFactory
  alias PurseCraft.PubSub.BroadcastWorkspace

  setup do
    workspace = CoreFactory.insert(:workspace)

    %{
      workspace: workspace
    }
  end

  describe "call/3" do
    test "with string keys in attrs creates a category correctly", %{workspace: workspace} do
      user = IdentityFactory.insert(:user)
      CoreFactory.insert(:workspace_user, workspace_id: workspace.id, user_id: user.id, role: :owner)
      scope = IdentityFactory.build(:scope, user: user)

      attrs = %{"name" => "String Key Category"}

      assert {:ok, %Category{} = category} = CreateCategory.call(scope, workspace, attrs)
      assert category.name == "String Key Category"
      assert category.workspace_id == workspace.id
      assert category.position == "m"
    end

    test "with invalid data returns error changeset", %{workspace: workspace} do
      user = IdentityFactory.insert(:user)
      CoreFactory.insert(:workspace_user, workspace_id: workspace.id, user_id: user.id, role: :owner)
      scope = IdentityFactory.build(:scope, user: user)

      attrs = %{name: ""}

      assert {:error, changeset} = CreateCategory.call(scope, workspace, attrs)
      assert %{name: ["can't be blank"]} = errors_on(changeset)
    end

    test "with owner role (authorized scope) creates a category", %{workspace: workspace} do
      user = IdentityFactory.insert(:user)
      CoreFactory.insert(:workspace_user, workspace_id: workspace.id, user_id: user.id, role: :owner)
      scope = IdentityFactory.build(:scope, user: user)

      attrs = %{name: "Owner Category"}

      assert {:ok, %Category{} = category} = CreateCategory.call(scope, workspace, attrs)
      assert category.name == "Owner Category"
      assert category.workspace_id == workspace.id
    end

    test "with editor role (authorized scope) creates a category", %{workspace: workspace} do
      user = IdentityFactory.insert(:user)
      CoreFactory.insert(:workspace_user, workspace_id: workspace.id, user_id: user.id, role: :editor)
      scope = IdentityFactory.build(:scope, user: user)

      attrs = %{name: "Editor Category"}

      assert {:ok, %Category{} = category} = CreateCategory.call(scope, workspace, attrs)
      assert category.name == "Editor Category"
      assert category.workspace_id == workspace.id
    end

    test "with commenter role (unauthorized scope) returns error", %{workspace: workspace} do
      user = IdentityFactory.insert(:user)
      CoreFactory.insert(:workspace_user, workspace_id: workspace.id, user_id: user.id, role: :commenter)
      scope = IdentityFactory.build(:scope, user: user)

      attrs = %{name: "Commenter Category"}

      assert {:error, :unauthorized} = CreateCategory.call(scope, workspace, attrs)
    end

    test "with no association to workspace (unauthorized scope) returns error", %{workspace: workspace} do
      user = IdentityFactory.insert(:user)
      scope = IdentityFactory.build(:scope, user: user)

      attrs = %{name: "Unauthorized Category"}

      assert {:error, :unauthorized} = CreateCategory.call(scope, workspace, attrs)
    end

    test "invokes BroadcastWorkspace when category is created successfully", %{workspace: workspace} do
      user = IdentityFactory.insert(:user)
      CoreFactory.insert(:workspace_user, workspace_id: workspace.id, user_id: user.id, role: :owner)
      scope = IdentityFactory.build(:scope, user: user)

      expect(BroadcastWorkspace, :call, fn broadcast_workspace, {:category_created, broadcast_category} ->
        assert broadcast_workspace == workspace
        assert broadcast_category.name == "Broadcast Test Category"
        :ok
      end)

      attrs = %{name: "Broadcast Test Category"}

      assert {:ok, %Category{}} = CreateCategory.call(scope, workspace, attrs)

      verify!()
    end

    test "assigns position 'm' for first category in a workspace", %{workspace: workspace} do
      user = IdentityFactory.insert(:user)
      CoreFactory.insert(:workspace_user, workspace_id: workspace.id, user_id: user.id, role: :owner)
      scope = IdentityFactory.build(:scope, user: user)

      attrs = %{name: "First Category"}

      assert {:ok, %Category{} = category} = CreateCategory.call(scope, workspace, attrs)
      assert category.position == "m"
    end

    test "assigns position before existing categories", %{workspace: workspace} do
      user = IdentityFactory.insert(:user)
      CoreFactory.insert(:workspace_user, workspace_id: workspace.id, user_id: user.id, role: :owner)
      scope = IdentityFactory.build(:scope, user: user)

      # Create first category
      BudgetingFactory.insert(:category, workspace: workspace, position: "m")

      attrs = %{name: "Second Category"}

      assert {:ok, %Category{} = category} = CreateCategory.call(scope, workspace, attrs)
      assert category.position < "m"
      assert category.position == "g"
    end

    test "handles multiple categories being added at the top", %{workspace: workspace} do
      user = IdentityFactory.insert(:user)
      CoreFactory.insert(:workspace_user, workspace_id: workspace.id, user_id: user.id, role: :owner)
      scope = IdentityFactory.build(:scope, user: user)

      # Create initial categories
      BudgetingFactory.insert(:category, workspace: workspace, position: "g")
      BudgetingFactory.insert(:category, workspace: workspace, position: "m")
      BudgetingFactory.insert(:category, workspace: workspace, position: "t")

      attrs = %{name: "New Top Category"}

      assert {:ok, %Category{} = category} = CreateCategory.call(scope, workspace, attrs)
      assert category.position < "g"
      assert category.position == "d"
    end

    test "returns error when first category is already at 'a'", %{workspace: workspace} do
      user = IdentityFactory.insert(:user)
      CoreFactory.insert(:workspace_user, workspace_id: workspace.id, user_id: user.id, role: :owner)
      scope = IdentityFactory.build(:scope, user: user)

      # Create a category at the boundary
      BudgetingFactory.insert(:category, workspace: workspace, position: "a")

      attrs = %{name: "Cannot Place At Top"}

      assert {:error, :cannot_place_at_top} = CreateCategory.call(scope, workspace, attrs)
    end
  end
end

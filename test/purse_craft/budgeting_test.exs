defmodule PurseCraft.BudgetingTest do
  use PurseCraft.DataCase, async: true

  alias PurseCraft.Budgeting
  alias PurseCraft.Budgeting.Schemas.Category
  alias PurseCraft.Budgeting.Schemas.Envelope
  alias PurseCraft.BudgetingFactory
  alias PurseCraft.Core
  alias PurseCraft.Core.Schemas.Workspace
  alias PurseCraft.Core.Schemas.WorkspaceUser
  alias PurseCraft.CoreFactory
  alias PurseCraft.IdentityFactory
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

  describe "fetch_workspace_by_external_id/3" do
    test "with associated workspace (authorized scope) returns workspace", %{scope: scope, workspace: workspace} do
      assert {:ok, fetched_workspace} = Core.fetch_workspace_by_external_id(scope, workspace.external_id)
      assert fetched_workspace.id == workspace.id
      assert fetched_workspace.name == workspace.name
      assert fetched_workspace.external_id == workspace.external_id
    end

    test "with associated workspace and preload options returns preloaded workspace", %{
      scope: scope,
      workspace: workspace
    } do
      category = BudgetingFactory.insert(:category, workspace_id: workspace.id)
      envelope = BudgetingFactory.insert(:envelope, category_id: category.id)

      assert {:ok, fetched_workspace} =
               Core.fetch_workspace_by_external_id(scope, workspace.external_id, preload: [categories: :envelopes])

      assert [loaded_category] = fetched_workspace.categories
      assert loaded_category.id == category.id
      assert loaded_category.name == category.name

      assert [loaded_envelope] = loaded_category.envelopes
      assert loaded_envelope.id == envelope.id
      assert loaded_envelope.name == envelope.name
    end

    test "with non-existent workspace returns unauthorized error" do
      user = IdentityFactory.insert(:user)
      scope = IdentityFactory.build(:scope, user: user)
      non_existent_id = Ecto.UUID.generate()

      assert {:error, :unauthorized} = Core.fetch_workspace_by_external_id(scope, non_existent_id)
    end

    test "with authorized scope but non-existent workspace returns not_found error" do
      user = IdentityFactory.insert(:user)
      scope = IdentityFactory.build(:scope, user: user)
      non_existent_id = Ecto.UUID.generate()

      Mimic.expect(PurseCraft.Core.Policy, :authorize, fn :workspace_read, _scope, _object ->
        :ok
      end)

      assert {:error, :not_found} = Core.fetch_workspace_by_external_id(scope, non_existent_id)
    end

    test "with no associated workspace (unauthorized scope) returns unauthorized error", %{workspace: workspace} do
      user = IdentityFactory.insert(:user)
      scope = IdentityFactory.build(:scope, user: user)

      assert {:error, :unauthorized} = Core.fetch_workspace_by_external_id(scope, workspace.external_id)
    end
  end

  describe "list_workspaces/1" do
    test "with associated workspaces returns all scoped workspaces", %{scope: scope, workspace: workspace} do
      other_user = IdentityFactory.insert(:user)
      other_scope = IdentityFactory.build(:scope, user: other_user)
      other_workspace = CoreFactory.insert(:workspace)

      CoreFactory.insert(:workspace_user, workspace_id: other_workspace.id, user_id: other_user.id)

      result = Core.list_workspaces(scope)
      assert [returned_workspace] = result
      assert returned_workspace.id == workspace.id
      assert returned_workspace.external_id == workspace.external_id
      assert returned_workspace.name == workspace.name

      other_result = Core.list_workspaces(other_scope)
      assert [returned_other_workspace] = other_result
      assert returned_other_workspace.id == other_workspace.id
      assert returned_other_workspace.external_id == other_workspace.external_id
      assert returned_other_workspace.name == other_workspace.name
    end

    test "with no associated workspaces returns empty list" do
      user = IdentityFactory.insert(:user)
      scope = IdentityFactory.build(:scope, user: user)

      assert Core.list_workspaces(scope) == []
    end
  end

  describe "get_workspace_by_external_id!/2" do
    test "with associated workspace (authorized scope) returns workspace", %{scope: scope, workspace: workspace} do
      result = Core.get_workspace_by_external_id!(scope, workspace.external_id)
      assert result.id == workspace.id
      assert result.external_id == workspace.external_id
      assert result.name == workspace.name
    end

    test "with no associated workspaces (unauthorized scope) raises `LetMe.UnauthorizedError`" do
      assert_raise LetMe.UnauthorizedError, fn ->
        user = IdentityFactory.insert(:user)
        scope = IdentityFactory.build(:scope, user: user)
        workspace = CoreFactory.insert(:workspace)

        Core.get_workspace_by_external_id!(scope, workspace.external_id)
      end
    end
  end

  describe "create_workspace/2" do
    test "with valid data creates a workspace" do
      user = IdentityFactory.insert(:user)
      scope = IdentityFactory.build(:scope, user: user)
      attrs = %{name: "some name"}

      assert {:ok, %Workspace{} = workspace} = Core.create_workspace(scope, attrs)
      assert workspace.name == "some name"

      workspace_user = Repo.get_by(WorkspaceUser, workspace_id: workspace.id)

      assert workspace_user.user_id == scope.user.id
      assert workspace_user.role == :owner
    end

    test "with no name returns error changeset" do
      user = IdentityFactory.insert(:user)
      scope = IdentityFactory.build(:scope, user: user)
      attrs = %{}

      assert {:error, changeset} = Core.create_workspace(scope, attrs)

      errors = errors_on(changeset)

      assert errors
             |> Map.keys()
             |> length() == 1

      assert %{name: ["can't be blank"]} = errors
    end
  end

  describe "update_workspace/3" do
    test "with associated workspace, owner role (authorized scope) and valid data updates the workspace", %{
      scope: scope,
      workspace: workspace
    } do
      attrs = %{name: "some updated name"}

      assert {:ok, %Workspace{} = updated_workspace} = Core.update_workspace(scope, workspace, attrs)
      assert updated_workspace.name == "some updated name"
    end

    test "with associated workspace, owner role (authorized scope) and invalid data returns error changeset", %{
      scope: scope,
      workspace: workspace
    } do
      attrs = %{name: ""}

      assert {:error, changeset} = Core.update_workspace(scope, workspace, attrs)

      errors = errors_on(changeset)

      assert errors
             |> Map.keys()
             |> length() == 1

      assert %{name: ["can't be blank"]} = errors
    end

    test "with associated workspace, non-owner role (unauthorized scope) and valid data updates the workspace", %{
      workspace: workspace
    } do
      user = IdentityFactory.insert(:user)
      CoreFactory.insert(:workspace_user, workspace_id: workspace.id, user_id: user.id, role: :editor)
      scope = IdentityFactory.build(:scope, user: user)

      attrs = %{name: "some updated name"}

      assert {:error, :unauthorized} = Core.update_workspace(scope, workspace, attrs)
    end

    test "with no associated workspace (unauthorized scope) returns error tuple", %{workspace: workspace} do
      user = IdentityFactory.insert(:user)
      scope = IdentityFactory.build(:scope, user: user)

      attrs = %{name: "some updated name"}

      assert {:error, :unauthorized} = Core.update_workspace(scope, workspace, attrs)
    end
  end

  describe "delete_workspace/2" do
    test "with associate workspace, owner role (authorized scope) deletes the workspace", %{
      scope: scope,
      workspace: workspace
    } do
      assert {:ok, %Workspace{}} = Core.delete_workspace(scope, workspace)

      assert_raise LetMe.UnauthorizedError, fn ->
        Core.get_workspace_by_external_id!(scope, workspace.external_id)
      end
    end

    test "with associated workspace, non-owner role (unauthorized scope) and valid data updates the workspace", %{
      workspace: workspace
    } do
      user = IdentityFactory.insert(:user)
      CoreFactory.insert(:workspace_user, workspace_id: workspace.id, user_id: user.id, role: :editor)
      scope = IdentityFactory.build(:scope, user: user)

      assert {:error, :unauthorized} = Core.delete_workspace(scope, workspace)
    end

    test "with no associated workspace (unauthorized scope) returns error tuple", %{workspace: workspace} do
      user = IdentityFactory.insert(:user)
      scope = IdentityFactory.build(:scope, user: user)

      assert {:error, :unauthorized} = Core.delete_workspace(scope, workspace)
    end
  end

  describe "change_workspace/2" do
    test "returns a workspace changeset" do
      workspace = CoreFactory.insert(:workspace)

      assert %Ecto.Changeset{} = Core.change_workspace(workspace, %{})
    end
  end

  describe "create_category/3" do
    test "with valid data creates a category", %{scope: scope, workspace: workspace} do
      attrs = %{name: "some category name"}

      assert {:ok, category} = Budgeting.create_category(scope, workspace, attrs)
      assert category.name == "some category name"
      assert category.workspace_id == workspace.id
    end

    test "with string keys in attrs creates a category correctly", %{scope: scope, workspace: workspace} do
      attrs = %{"name" => "string key category"}

      assert {:ok, category} = Budgeting.create_category(scope, workspace, attrs)
      assert category.name == "string key category"
      assert category.workspace_id == workspace.id
    end

    test "with mixed string and atom keys creates a category correctly", %{scope: scope, workspace: workspace} do
      attrs = %{"name" => "mixed keys category", priority: 1}

      assert {:ok, category} = Budgeting.create_category(scope, workspace, attrs)
      assert category.name == "mixed keys category"
    end

    test "with invalid data returns error changeset", %{scope: scope, workspace: workspace} do
      attrs = %{name: ""}

      assert {:error, changeset} = Budgeting.create_category(scope, workspace, attrs)
      assert %{name: ["can't be blank"]} = errors_on(changeset)
    end

    test "with owner role (authorized scope) creates a category", %{scope: scope, workspace: workspace} do
      # The default setup already has owner role
      attrs = %{name: "owner category"}

      assert {:ok, category} = Budgeting.create_category(scope, workspace, attrs)
      assert category.name == "owner category"
    end

    test "with editor role (authorized scope) creates a category", %{workspace: workspace} do
      user = IdentityFactory.insert(:user)
      CoreFactory.insert(:workspace_user, workspace_id: workspace.id, user_id: user.id, role: :editor)
      scope = IdentityFactory.build(:scope, user: user)

      attrs = %{name: "editor category"}

      assert {:ok, category} = Budgeting.create_category(scope, workspace, attrs)
      assert category.name == "editor category"
    end

    test "with commenter role (unauthorized scope) returns error", %{workspace: workspace} do
      user = IdentityFactory.insert(:user)
      CoreFactory.insert(:workspace_user, workspace_id: workspace.id, user_id: user.id, role: :commenter)
      scope = IdentityFactory.build(:scope, user: user)

      attrs = %{name: "commenter category"}

      assert {:error, :unauthorized} = Budgeting.create_category(scope, workspace, attrs)
    end

    test "with no association to workspace (unauthorized scope) returns error", %{workspace: workspace} do
      user = IdentityFactory.insert(:user)
      scope = IdentityFactory.build(:scope, user: user)

      attrs = %{name: "unauthorized category"}

      assert {:error, :unauthorized} = Budgeting.create_category(scope, workspace, attrs)
    end
  end

  describe "delete_category/3" do
    setup %{workspace: workspace} do
      category = BudgetingFactory.insert(:category, workspace_id: workspace.id)
      %{category: category}
    end

    test "with associated category, owner role (authorized scope) deletes the category", %{
      scope: scope,
      workspace: workspace,
      category: category
    } do
      assert {:ok, %Category{}} = Budgeting.delete_category(scope, workspace, category)
      assert {:error, :not_found} = Budgeting.fetch_category_by_external_id(scope, workspace, category.external_id)
    end

    test "with associated category, editor role (authorized scope) deletes the category", %{
      workspace: workspace,
      category: category
    } do
      user = IdentityFactory.insert(:user)
      CoreFactory.insert(:workspace_user, workspace_id: workspace.id, user_id: user.id, role: :editor)
      scope = IdentityFactory.build(:scope, user: user)

      assert {:ok, %Category{}} = Budgeting.delete_category(scope, workspace, category)
      assert {:error, :not_found} = Budgeting.fetch_category_by_external_id(scope, workspace, category.external_id)
    end

    test "with commenter role (unauthorized scope) returns error", %{
      workspace: workspace,
      category: category
    } do
      user = IdentityFactory.insert(:user)
      CoreFactory.insert(:workspace_user, workspace_id: workspace.id, user_id: user.id, role: :commenter)
      scope = IdentityFactory.build(:scope, user: user)

      assert {:error, :unauthorized} = Budgeting.delete_category(scope, workspace, category)
    end

    test "with no association to workspace (unauthorized scope) returns error", %{
      workspace: workspace,
      category: category
    } do
      user = IdentityFactory.insert(:user)
      scope = IdentityFactory.build(:scope, user: user)

      assert {:error, :unauthorized} = Budgeting.delete_category(scope, workspace, category)
    end
  end

  describe "fetch_category_by_external_id/4" do
    setup %{workspace: workspace} do
      category = BudgetingFactory.insert(:category, workspace_id: workspace.id)
      envelope = BudgetingFactory.insert(:envelope, category_id: category.id)

      %{category: category, envelope: envelope}
    end

    test "with associated category (authorized scope) returns category", %{
      scope: scope,
      workspace: workspace,
      category: category
    } do
      assert {:ok, fetched_category} = Budgeting.fetch_category_by_external_id(scope, workspace, category.external_id)
      assert fetched_category.id == category.id
      assert fetched_category.name == category.name
      assert fetched_category.external_id == category.external_id
      assert fetched_category.workspace_id == workspace.id
    end

    test "with associated category and preload options returns preloaded category", %{
      scope: scope,
      workspace: workspace,
      category: category,
      envelope: envelope
    } do
      assert {:ok, fetched_category} =
               Budgeting.fetch_category_by_external_id(scope, workspace, category.external_id, preload: [:envelopes])

      assert fetched_category.id == category.id
      assert fetched_category.name == category.name
      assert fetched_category.external_id == category.external_id

      assert [loaded_envelope] = fetched_category.envelopes
      assert loaded_envelope.id == envelope.id
      assert loaded_envelope.name == envelope.name
    end

    test "with non-existent category returns not_found error", %{scope: scope, workspace: workspace} do
      non_existent_id = Ecto.UUID.generate()

      assert {:error, :not_found} = Budgeting.fetch_category_by_external_id(scope, workspace, non_existent_id)
    end

    test "with category from a different workspace returns not_found error", %{scope: scope, workspace: workspace} do
      other_workspace = CoreFactory.insert(:workspace)
      CoreFactory.insert(:workspace_user, workspace_id: other_workspace.id, user_id: scope.user.id, role: :owner)

      other_category = BudgetingFactory.insert(:category, workspace_id: other_workspace.id)

      # Trying to fetch a category using its external_id but with the wrong workspace
      assert {:error, :not_found} =
               Budgeting.fetch_category_by_external_id(scope, workspace, other_category.external_id)
    end

    test "with editor role (authorized scope) returns category", %{
      workspace: workspace,
      category: category
    } do
      user = IdentityFactory.insert(:user)
      CoreFactory.insert(:workspace_user, workspace_id: workspace.id, user_id: user.id, role: :editor)
      scope = IdentityFactory.build(:scope, user: user)

      assert {:ok, fetched_category} = Budgeting.fetch_category_by_external_id(scope, workspace, category.external_id)
      assert fetched_category.id == category.id
    end

    test "with commenter role (authorized scope) returns category", %{
      workspace: workspace,
      category: category
    } do
      user = IdentityFactory.insert(:user)
      CoreFactory.insert(:workspace_user, workspace_id: workspace.id, user_id: user.id, role: :commenter)
      scope = IdentityFactory.build(:scope, user: user)

      assert {:ok, fetched_category} = Budgeting.fetch_category_by_external_id(scope, workspace, category.external_id)
      assert fetched_category.id == category.id
    end

    test "with no association to workspace (unauthorized scope) returns error", %{
      workspace: workspace,
      category: category
    } do
      user = IdentityFactory.insert(:user)
      scope = IdentityFactory.build(:scope, user: user)

      assert {:error, :unauthorized} = Budgeting.fetch_category_by_external_id(scope, workspace, category.external_id)
    end
  end

  describe "list_categories/3" do
    setup %{workspace: workspace} do
      categories =
        for _index <- 1..3 do
          BudgetingFactory.insert(:category, workspace_id: workspace.id)
        end

      other_workspace = CoreFactory.insert(:workspace)
      other_category = BudgetingFactory.insert(:category, workspace_id: other_workspace.id)

      %{categories: categories, other_workspace: other_workspace, other_category: other_category}
    end

    test "with associated workspace (authorized scope) returns all workspace categories", %{
      scope: scope,
      workspace: workspace,
      categories: categories
    } do
      result = Budgeting.list_categories(scope, workspace)

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

      result = Budgeting.list_categories(scope, workspace, preload: [:envelopes])

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

      result = Budgeting.list_categories(scope, workspace)
      assert length(result) == length(categories)
    end

    test "with commenter role (authorized scope) returns categories", %{
      workspace: workspace,
      categories: categories
    } do
      user = IdentityFactory.insert(:user)
      CoreFactory.insert(:workspace_user, workspace_id: workspace.id, user_id: user.id, role: :commenter)
      scope = IdentityFactory.build(:scope, user: user)

      result = Budgeting.list_categories(scope, workspace)
      assert length(result) == length(categories)
    end

    test "with no association to workspace (unauthorized scope) returns error", %{
      workspace: workspace
    } do
      user = IdentityFactory.insert(:user)
      scope = IdentityFactory.build(:scope, user: user)

      assert {:error, :unauthorized} = Budgeting.list_categories(scope, workspace)
    end

    test "returns only categories for the specified workspace", %{
      scope: scope,
      workspace: workspace,
      categories: categories,
      other_workspace: other_workspace,
      other_category: other_category
    } do
      CoreFactory.insert(:workspace_user, workspace_id: other_workspace.id, user_id: scope.user.id, role: :owner)

      workspace_categories = Budgeting.list_categories(scope, workspace)
      assert length(workspace_categories) == length(categories)
      assert Enum.all?(workspace_categories, fn cat -> cat.workspace_id == workspace.id end)

      other_workspace_categories = Budgeting.list_categories(scope, other_workspace)
      assert length(other_workspace_categories) == 1
      assert hd(other_workspace_categories).id == other_category.id
    end
  end

  describe "update_category/5" do
    setup %{workspace: workspace} do
      category = BudgetingFactory.insert(:category, workspace_id: workspace.id)
      envelope = BudgetingFactory.insert(:envelope, category_id: category.id)

      %{category: category, envelope: envelope}
    end

    test "with owner role (authorized scope) and valid data updates the category", %{
      scope: scope,
      workspace: workspace,
      category: category
    } do
      attrs = %{name: "updated category name"}

      assert {:ok, updated_category} = Budgeting.update_category(scope, workspace, category, attrs)
      assert updated_category.name == "updated category name"
      assert updated_category.workspace_id == workspace.id
    end

    test "with preload option returns category with associations", %{
      scope: scope,
      workspace: workspace,
      category: category,
      envelope: envelope
    } do
      attrs = %{name: "updated with preload"}

      assert {:ok, updated_category} =
               Budgeting.update_category(scope, workspace, category, attrs, preload: [:envelopes])

      assert updated_category.name == "updated with preload"
      assert [loaded_envelope] = updated_category.envelopes
      assert loaded_envelope.id == envelope.id
    end

    test "with editor role (authorized scope) and valid data updates the category", %{
      workspace: workspace,
      category: category
    } do
      user = IdentityFactory.insert(:user)
      CoreFactory.insert(:workspace_user, workspace_id: workspace.id, user_id: user.id, role: :editor)
      scope = IdentityFactory.build(:scope, user: user)

      attrs = %{name: "editor updated category"}

      assert {:ok, updated_category} = Budgeting.update_category(scope, workspace, category, attrs)
      assert updated_category.name == "editor updated category"
    end

    test "with commenter role (unauthorized scope) returns error", %{
      workspace: workspace,
      category: category
    } do
      user = IdentityFactory.insert(:user)
      CoreFactory.insert(:workspace_user, workspace_id: workspace.id, user_id: user.id, role: :commenter)
      scope = IdentityFactory.build(:scope, user: user)

      attrs = %{name: "commenter category"}

      assert {:error, :unauthorized} = Budgeting.update_category(scope, workspace, category, attrs)
    end

    test "with no association to workspace (unauthorized scope) returns error", %{
      workspace: workspace,
      category: category
    } do
      user = IdentityFactory.insert(:user)
      scope = IdentityFactory.build(:scope, user: user)

      attrs = %{name: "unauthorized category update"}

      assert {:error, :unauthorized} = Budgeting.update_category(scope, workspace, category, attrs)
    end

    test "with invalid data returns error changeset", %{
      scope: scope,
      workspace: workspace,
      category: category
    } do
      attrs = %{name: ""}

      assert {:error, changeset} = Budgeting.update_category(scope, workspace, category, attrs)
      assert %{name: ["can't be blank"]} = errors_on(changeset)
    end

    test "with string keys in attrs updates the category correctly", %{
      scope: scope,
      workspace: workspace,
      category: category
    } do
      attrs = %{"name" => "string key updated category"}

      assert {:ok, updated_category} = Budgeting.update_category(scope, workspace, category, attrs)
      assert updated_category.name == "string key updated category"
    end
  end

  describe "change_category/2" do
    test "returns a category changeset", %{workspace: workspace} do
      category = BudgetingFactory.insert(:category, workspace_id: workspace.id)

      assert %Ecto.Changeset{} = Budgeting.change_category(category, %{})
    end
  end

  describe "create_envelope/4" do
    setup %{workspace: workspace} do
      category = BudgetingFactory.insert(:category, workspace_id: workspace.id)
      %{category: category}
    end

    test "with valid data creates an envelope", %{scope: scope, workspace: workspace, category: category} do
      attrs = %{name: "some envelope name"}

      assert {:ok, envelope} = Budgeting.create_envelope(scope, workspace, category, attrs)
      assert envelope.name == "some envelope name"
      assert envelope.category_id == category.id
    end

    test "with string keys in attrs creates an envelope correctly", %{
      scope: scope,
      workspace: workspace,
      category: category
    } do
      attrs = %{"name" => "string key envelope"}

      assert {:ok, envelope} = Budgeting.create_envelope(scope, workspace, category, attrs)
      assert envelope.name == "string key envelope"
      assert envelope.category_id == category.id
    end

    test "with invalid data returns error changeset", %{scope: scope, workspace: workspace, category: category} do
      attrs = %{name: ""}

      assert {:error, changeset} = Budgeting.create_envelope(scope, workspace, category, attrs)
      assert %{name: ["can't be blank"]} = errors_on(changeset)
    end

    test "with owner role (authorized scope) creates an envelope", %{
      scope: scope,
      workspace: workspace,
      category: category
    } do
      attrs = %{name: "owner envelope"}

      assert {:ok, envelope} = Budgeting.create_envelope(scope, workspace, category, attrs)
      assert envelope.name == "owner envelope"
    end

    test "with editor role (authorized scope) creates an envelope", %{workspace: workspace, category: category} do
      user = IdentityFactory.insert(:user)
      CoreFactory.insert(:workspace_user, workspace_id: workspace.id, user_id: user.id, role: :editor)
      scope = IdentityFactory.build(:scope, user: user)

      attrs = %{name: "editor envelope"}

      assert {:ok, envelope} = Budgeting.create_envelope(scope, workspace, category, attrs)
      assert envelope.name == "editor envelope"
    end

    test "with commenter role (unauthorized scope) returns error", %{workspace: workspace, category: category} do
      user = IdentityFactory.insert(:user)
      CoreFactory.insert(:workspace_user, workspace_id: workspace.id, user_id: user.id, role: :commenter)
      scope = IdentityFactory.build(:scope, user: user)

      attrs = %{name: "commenter envelope"}

      assert {:error, :unauthorized} = Budgeting.create_envelope(scope, workspace, category, attrs)
    end

    test "with no association to workspace (unauthorized scope) returns error", %{
      workspace: workspace,
      category: category
    } do
      user = IdentityFactory.insert(:user)
      scope = IdentityFactory.build(:scope, user: user)

      attrs = %{name: "unauthorized envelope"}

      assert {:error, :unauthorized} = Budgeting.create_envelope(scope, workspace, category, attrs)
    end
  end

  describe "fetch_envelope_by_external_id/3" do
    setup %{workspace: workspace} do
      category = BudgetingFactory.insert(:category, workspace_id: workspace.id)
      envelope = BudgetingFactory.insert(:envelope, category_id: category.id)

      %{category: category, envelope: envelope}
    end

    test "with associated envelope (authorized scope) returns envelope", %{
      scope: scope,
      workspace: workspace,
      envelope: envelope
    } do
      assert {:ok, fetched_envelope} = Budgeting.fetch_envelope_by_external_id(scope, workspace, envelope.external_id)
      assert fetched_envelope.id == envelope.id
      assert fetched_envelope.name == envelope.name
      assert fetched_envelope.external_id == envelope.external_id
      assert fetched_envelope.category_id == envelope.category_id
    end

    test "with non-existent envelope returns not_found error", %{scope: scope, workspace: workspace} do
      non_existent_id = Ecto.UUID.generate()

      assert {:error, :not_found} = Budgeting.fetch_envelope_by_external_id(scope, workspace, non_existent_id)
    end

    test "with envelope from a different workspace returns not_found error", %{scope: scope, workspace: workspace} do
      other_workspace = CoreFactory.insert(:workspace)
      CoreFactory.insert(:workspace_user, workspace_id: other_workspace.id, user_id: scope.user.id, role: :owner)

      other_category = BudgetingFactory.insert(:category, workspace_id: other_workspace.id)
      other_envelope = BudgetingFactory.insert(:envelope, category_id: other_category.id)

      assert {:error, :not_found} =
               Budgeting.fetch_envelope_by_external_id(scope, workspace, other_envelope.external_id)
    end

    test "with editor role (authorized scope) returns envelope", %{
      workspace: workspace,
      envelope: envelope
    } do
      user = IdentityFactory.insert(:user)
      CoreFactory.insert(:workspace_user, workspace_id: workspace.id, user_id: user.id, role: :editor)
      scope = IdentityFactory.build(:scope, user: user)

      assert {:ok, fetched_envelope} = Budgeting.fetch_envelope_by_external_id(scope, workspace, envelope.external_id)
      assert fetched_envelope.id == envelope.id
    end

    test "with commenter role (authorized scope) returns envelope", %{
      workspace: workspace,
      envelope: envelope
    } do
      user = IdentityFactory.insert(:user)
      CoreFactory.insert(:workspace_user, workspace_id: workspace.id, user_id: user.id, role: :commenter)
      scope = IdentityFactory.build(:scope, user: user)

      assert {:ok, fetched_envelope} = Budgeting.fetch_envelope_by_external_id(scope, workspace, envelope.external_id)
      assert fetched_envelope.id == envelope.id
    end

    test "with no association to workspace (unauthorized scope) returns error", %{
      workspace: workspace,
      envelope: envelope
    } do
      user = IdentityFactory.insert(:user)
      scope = IdentityFactory.build(:scope, user: user)

      assert {:error, :unauthorized} = Budgeting.fetch_envelope_by_external_id(scope, workspace, envelope.external_id)
    end
  end

  describe "update_envelope/4" do
    setup %{workspace: workspace} do
      category = BudgetingFactory.insert(:category, workspace_id: workspace.id)
      envelope = BudgetingFactory.insert(:envelope, category_id: category.id)

      %{category: category, envelope: envelope}
    end

    test "with owner role (authorized scope) and valid data updates the envelope", %{
      scope: scope,
      workspace: workspace,
      envelope: envelope
    } do
      attrs = %{name: "updated envelope name"}

      assert {:ok, updated_envelope} = Budgeting.update_envelope(scope, workspace, envelope, attrs)
      assert updated_envelope.name == "updated envelope name"
      assert updated_envelope.category_id == envelope.category_id
    end

    test "with editor role (authorized scope) and valid data updates the envelope", %{
      workspace: workspace,
      envelope: envelope
    } do
      user = IdentityFactory.insert(:user)
      CoreFactory.insert(:workspace_user, workspace_id: workspace.id, user_id: user.id, role: :editor)
      scope = IdentityFactory.build(:scope, user: user)

      attrs = %{name: "editor updated envelope"}

      assert {:ok, updated_envelope} = Budgeting.update_envelope(scope, workspace, envelope, attrs)
      assert updated_envelope.name == "editor updated envelope"
    end

    test "with commenter role (unauthorized scope) returns error", %{
      workspace: workspace,
      envelope: envelope
    } do
      user = IdentityFactory.insert(:user)
      CoreFactory.insert(:workspace_user, workspace_id: workspace.id, user_id: user.id, role: :commenter)
      scope = IdentityFactory.build(:scope, user: user)

      attrs = %{name: "commenter envelope"}

      assert {:error, :unauthorized} = Budgeting.update_envelope(scope, workspace, envelope, attrs)
    end

    test "with no association to workspace (unauthorized scope) returns error", %{
      workspace: workspace,
      envelope: envelope
    } do
      user = IdentityFactory.insert(:user)
      scope = IdentityFactory.build(:scope, user: user)

      attrs = %{name: "unauthorized envelope update"}

      assert {:error, :unauthorized} = Budgeting.update_envelope(scope, workspace, envelope, attrs)
    end

    test "with invalid data returns error changeset", %{
      scope: scope,
      workspace: workspace,
      envelope: envelope
    } do
      attrs = %{name: ""}

      assert {:error, changeset} = Budgeting.update_envelope(scope, workspace, envelope, attrs)
      assert %{name: ["can't be blank"]} = errors_on(changeset)
    end

    test "with string keys in attrs updates the envelope correctly", %{
      scope: scope,
      workspace: workspace,
      envelope: envelope
    } do
      attrs = %{"name" => "string key updated envelope"}

      assert {:ok, updated_envelope} = Budgeting.update_envelope(scope, workspace, envelope, attrs)
      assert updated_envelope.name == "string key updated envelope"
    end
  end

  describe "delete_envelope/3" do
    setup %{workspace: workspace} do
      category = BudgetingFactory.insert(:category, workspace_id: workspace.id)
      envelope = BudgetingFactory.insert(:envelope, category_id: category.id)
      %{category: category, envelope: envelope}
    end

    test "with associated envelope, owner role (authorized scope) deletes the envelope", %{
      scope: scope,
      workspace: workspace,
      envelope: envelope
    } do
      assert {:ok, %Envelope{}} = Budgeting.delete_envelope(scope, workspace, envelope)
      assert {:error, :not_found} = Budgeting.fetch_envelope_by_external_id(scope, workspace, envelope.external_id)
    end

    test "with associated envelope, editor role (authorized scope) deletes the envelope", %{
      workspace: workspace,
      envelope: envelope
    } do
      user = IdentityFactory.insert(:user)
      CoreFactory.insert(:workspace_user, workspace_id: workspace.id, user_id: user.id, role: :editor)
      scope = IdentityFactory.build(:scope, user: user)

      assert {:ok, %Envelope{}} = Budgeting.delete_envelope(scope, workspace, envelope)
      assert {:error, :not_found} = Budgeting.fetch_envelope_by_external_id(scope, workspace, envelope.external_id)
    end

    test "with commenter role (unauthorized scope) returns error", %{
      workspace: workspace,
      envelope: envelope
    } do
      user = IdentityFactory.insert(:user)
      CoreFactory.insert(:workspace_user, workspace_id: workspace.id, user_id: user.id, role: :commenter)
      scope = IdentityFactory.build(:scope, user: user)

      assert {:error, :unauthorized} = Budgeting.delete_envelope(scope, workspace, envelope)
    end

    test "with no association to workspace (unauthorized scope) returns error", %{
      workspace: workspace,
      envelope: envelope
    } do
      user = IdentityFactory.insert(:user)
      scope = IdentityFactory.build(:scope, user: user)

      assert {:error, :unauthorized} = Budgeting.delete_envelope(scope, workspace, envelope)
    end
  end
end

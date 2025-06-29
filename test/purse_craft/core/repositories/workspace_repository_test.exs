defmodule PurseCraft.Core.Repositories.WorkspaceRepositoryTest do
  use PurseCraft.DataCase, async: true

  alias PurseCraft.BudgetingFactory
  alias PurseCraft.Core.Repositories.WorkspaceRepository
  alias PurseCraft.Core.Schemas.Workspace
  alias PurseCraft.Core.Schemas.WorkspaceUser
  alias PurseCraft.CoreFactory
  alias PurseCraft.IdentityFactory
  alias PurseCraft.Repo

  describe "list_by_user/1" do
    test "returns all workspaces associated with a user" do
      user = IdentityFactory.insert(:user)
      workspace = CoreFactory.insert(:workspace)
      CoreFactory.insert(:workspace_user, workspace_id: workspace.id, user_id: user.id, role: :owner)

      other_user = IdentityFactory.insert(:user)
      other_workspace = CoreFactory.insert(:workspace)
      CoreFactory.insert(:workspace_user, workspace_id: other_workspace.id, user_id: other_user.id)

      result = WorkspaceRepository.list_by_user(user.id)
      assert [returned_workspace] = result
      assert returned_workspace.id == workspace.id
      assert returned_workspace.external_id == workspace.external_id
      assert returned_workspace.name == workspace.name

      other_result = WorkspaceRepository.list_by_user(other_user.id)
      assert [returned_other_workspace] = other_result
      assert returned_other_workspace.id == other_workspace.id
      assert returned_other_workspace.external_id == other_workspace.external_id
      assert returned_other_workspace.name == other_workspace.name
    end

    test "with no associated workspaces returns empty list" do
      user = IdentityFactory.insert(:user)

      assert WorkspaceRepository.list_by_user(user.id) == []
    end
  end

  describe "get_by_external_id!/1" do
    test "with existing workspace returns the workspace" do
      workspace = CoreFactory.insert(:workspace)

      result = WorkspaceRepository.get_by_external_id!(workspace.external_id)
      assert result.id == workspace.id
      assert result.external_id == workspace.external_id
      assert result.name == workspace.name
    end

    test "with non-existent workspace raises Ecto.NoResultsError" do
      assert_raise Ecto.NoResultsError, fn ->
        non_existent_id = Ecto.UUID.generate()

        WorkspaceRepository.get_by_external_id!(non_existent_id)
      end
    end
  end

  describe "get_by_external_id/1" do
    test "with existing workspace returns the workspace" do
      workspace = CoreFactory.insert(:workspace)

      result = WorkspaceRepository.get_by_external_id(workspace.external_id)
      assert result.id == workspace.id
      assert result.external_id == workspace.external_id
      assert result.name == workspace.name
    end

    test "with non-existent workspace returns nil" do
      non_existent_id = Ecto.UUID.generate()

      assert WorkspaceRepository.get_by_external_id(non_existent_id) == nil
    end
  end

  describe "get_by_external_id/2" do
    test "with existing workspace returns the workspace" do
      workspace = CoreFactory.insert(:workspace)

      result = WorkspaceRepository.get_by_external_id(workspace.external_id)
      assert result.id == workspace.id
      assert result.external_id == workspace.external_id
      assert result.name == workspace.name
    end

    test "with non-existent workspace returns nil" do
      non_existent_id = Ecto.UUID.generate()

      assert WorkspaceRepository.get_by_external_id(non_existent_id) == nil
    end

    test "with preload option loads the association" do
      workspace = CoreFactory.insert(:workspace)
      category1 = BudgetingFactory.insert(:category, workspace_id: workspace.id, position: "g")
      category2 = BudgetingFactory.insert(:category, workspace_id: workspace.id, position: "h")

      workspace_with_categories = WorkspaceRepository.get_by_external_id(workspace.external_id, preload: [:categories])

      assert Enum.count(workspace_with_categories.categories) == 2
      assert Enum.any?(workspace_with_categories.categories, &(&1.id == category1.id))
      assert Enum.any?(workspace_with_categories.categories, &(&1.id == category2.id))
    end

    test "with empty preload list returns the workspace without preloading" do
      workspace = CoreFactory.insert(:workspace)
      BudgetingFactory.insert(:category, workspace_id: workspace.id, position: "g")

      workspace_without_preload = WorkspaceRepository.get_by_external_id(workspace.external_id, preload: [])

      assert workspace_without_preload.id == workspace.id
      assert match?(%Ecto.Association.NotLoaded{}, workspace_without_preload.categories)
    end
  end

  describe "create/2" do
    test "with valid data creates a workspace and associates it with a user" do
      user = IdentityFactory.insert(:user)
      attrs = %{name: "Test Workspace"}

      assert {:ok, workspace} = WorkspaceRepository.create(attrs, user.id)
      assert workspace.name == "Test Workspace"

      workspace_user = PurseCraft.Repo.get_by(PurseCraft.Core.Schemas.WorkspaceUser, workspace_id: workspace.id)
      assert workspace_user.user_id == user.id
      assert workspace_user.role == :owner
    end

    test "with invalid data returns error changeset" do
      user = IdentityFactory.insert(:user)
      attrs = %{name: ""}

      assert {:error, changeset} = WorkspaceRepository.create(attrs, user.id)
      assert %{name: ["can't be blank"]} = errors_on(changeset)
    end
  end

  describe "update/2" do
    test "with valid data updates the workspace" do
      workspace = CoreFactory.insert(:workspace, name: "Original Name")
      attrs = %{name: "Updated Name"}

      assert {:ok, updated_workspace} = WorkspaceRepository.update(workspace, attrs)
      assert updated_workspace.name == "Updated Name"
      assert updated_workspace.id == workspace.id
      assert updated_workspace.external_id == workspace.external_id
    end

    test "with invalid data returns error changeset" do
      workspace = CoreFactory.insert(:workspace, name: "Original Name")
      attrs = %{name: ""}

      assert {:error, changeset} = WorkspaceRepository.update(workspace, attrs)
      assert %{name: ["can't be blank"]} = errors_on(changeset)

      reloaded_workspace = Repo.get(Workspace, workspace.id)
      assert reloaded_workspace.name == "Original Name"
    end
  end

  describe "delete/1" do
    test "deletes the workspace successfully" do
      workspace = CoreFactory.insert(:workspace)

      assert {:ok, deleted_workspace} = WorkspaceRepository.delete(workspace)
      assert deleted_workspace.id == workspace.id
      assert Repo.get(Workspace, workspace.id) == nil
    end

    test "deletes associated workspace_user records" do
      workspace = CoreFactory.insert(:workspace)
      user1 = IdentityFactory.insert(:user)
      user2 = IdentityFactory.insert(:user)

      workspace_user1 = CoreFactory.insert(:workspace_user, workspace_id: workspace.id, user_id: user1.id, role: :owner)
      workspace_user2 = CoreFactory.insert(:workspace_user, workspace_id: workspace.id, user_id: user2.id, role: :editor)

      assert {:ok, _deleted_workspace} = WorkspaceRepository.delete(workspace)

      assert Repo.get(Workspace, workspace.id) == nil
      assert Repo.get(WorkspaceUser, workspace_user1.id) == nil
      assert Repo.get(WorkspaceUser, workspace_user2.id) == nil
    end
  end
end

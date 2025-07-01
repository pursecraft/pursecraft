defmodule PurseCraft.Budgeting.Commands.Categories.RepositionCategoryTest do
  use PurseCraft.DataCase, async: true

  import Mimic

  alias PurseCraft.Budgeting.Commands.Categories.RepositionCategory
  alias PurseCraft.Budgeting.Repositories.CategoryRepository
  alias PurseCraft.Budgeting.Schemas.Category
  alias PurseCraft.BudgetingFactory
  alias PurseCraft.CoreFactory
  alias PurseCraft.IdentityFactory
  alias PurseCraft.PubSub.BroadcastWorkspace

  setup do
    workspace = CoreFactory.insert(:workspace)

    cat1 = BudgetingFactory.insert(:category, workspace_id: workspace.id, position: "g")
    cat2 = BudgetingFactory.insert(:category, workspace_id: workspace.id, position: "m")
    cat3 = BudgetingFactory.insert(:category, workspace_id: workspace.id, position: "t")

    %{
      workspace: workspace,
      cat1: cat1,
      cat2: cat2,
      cat3: cat3
    }
  end

  describe "call/4" do
    test "successfully repositions category between two others", %{
      workspace: workspace,
      cat1: cat1,
      cat2: cat2,
      cat3: cat3
    } do
      user = IdentityFactory.insert(:user)
      CoreFactory.insert(:workspace_user, workspace_id: workspace.id, user_id: user.id, role: :owner)
      scope = IdentityFactory.build(:scope, user: user)

      assert {:ok, updated} = RepositionCategory.call(scope, cat3.external_id, cat1.external_id, cat2.external_id)

      assert updated.id == cat3.id
      assert updated.position > cat1.position
      assert updated.position < cat2.position
    end

    test "repositions category to the beginning when prev_category_id is nil", %{
      workspace: workspace,
      cat1: cat1,
      cat3: cat3
    } do
      user = IdentityFactory.insert(:user)
      CoreFactory.insert(:workspace_user, workspace_id: workspace.id, user_id: user.id, role: :owner)
      scope = IdentityFactory.build(:scope, user: user)

      assert {:ok, updated} = RepositionCategory.call(scope, cat3.external_id, nil, cat1.external_id)

      assert updated.id == cat3.id
      assert updated.position < cat1.position
    end

    test "repositions category to the end when next_category_id is nil", %{workspace: workspace, cat1: cat1, cat3: cat3} do
      user = IdentityFactory.insert(:user)
      CoreFactory.insert(:workspace_user, workspace_id: workspace.id, user_id: user.id, role: :owner)
      scope = IdentityFactory.build(:scope, user: user)

      assert {:ok, updated} = RepositionCategory.call(scope, cat1.external_id, cat3.external_id, nil)

      assert updated.id == cat1.id
      assert updated.position > cat3.position
    end

    test "returns not_found when category doesn't exist", %{workspace: workspace, cat1: cat1, cat2: cat2} do
      user = IdentityFactory.insert(:user)
      CoreFactory.insert(:workspace_user, workspace_id: workspace.id, user_id: user.id, role: :owner)
      scope = IdentityFactory.build(:scope, user: user)

      assert {:error, :not_found} =
               RepositionCategory.call(scope, Ecto.UUID.generate(), cat1.external_id, cat2.external_id)
    end

    test "returns not_found when prev_category doesn't exist", %{workspace: workspace, cat1: cat1, cat2: cat2} do
      user = IdentityFactory.insert(:user)
      CoreFactory.insert(:workspace_user, workspace_id: workspace.id, user_id: user.id, role: :owner)
      scope = IdentityFactory.build(:scope, user: user)

      assert {:error, :not_found} =
               RepositionCategory.call(scope, cat1.external_id, Ecto.UUID.generate(), cat2.external_id)
    end

    test "returns not_found when next_category doesn't exist", %{workspace: workspace, cat1: cat1, cat2: cat2} do
      user = IdentityFactory.insert(:user)
      CoreFactory.insert(:workspace_user, workspace_id: workspace.id, user_id: user.id, role: :owner)
      scope = IdentityFactory.build(:scope, user: user)

      assert {:error, :not_found} =
               RepositionCategory.call(scope, cat1.external_id, cat2.external_id, Ecto.UUID.generate())
    end

    test "returns not_found when prev_category is from different workspace", %{
      workspace: workspace,
      cat1: cat1,
      cat2: cat2
    } do
      user = IdentityFactory.insert(:user)
      CoreFactory.insert(:workspace_user, workspace_id: workspace.id, user_id: user.id, role: :owner)
      scope = IdentityFactory.build(:scope, user: user)

      other_workspace = CoreFactory.insert(:workspace)
      other_cat = BudgetingFactory.insert(:category, workspace_id: other_workspace.id, position: "a")

      assert {:error, :not_found} =
               RepositionCategory.call(scope, cat1.external_id, other_cat.external_id, cat2.external_id)
    end

    test "returns unauthorized when user lacks permission", %{workspace: workspace, cat1: cat1, cat2: cat2, cat3: cat3} do
      user = IdentityFactory.insert(:user)
      CoreFactory.insert(:workspace_user, workspace_id: workspace.id, user_id: user.id, role: :commenter)
      scope = IdentityFactory.build(:scope, user: user)

      assert {:error, :unauthorized} =
               RepositionCategory.call(scope, cat3.external_id, cat1.external_id, cat2.external_id)
    end

    test "returns error when fractional indexing fails", %{workspace: workspace} do
      user = IdentityFactory.insert(:user)
      CoreFactory.insert(:workspace_user, workspace_id: workspace.id, user_id: user.id, role: :owner)
      scope = IdentityFactory.build(:scope, user: user)

      cat1 = BudgetingFactory.insert(:category, workspace_id: workspace.id, position: "z")
      cat2 = BudgetingFactory.insert(:category, workspace_id: workspace.id, position: "a")
      cat3 = BudgetingFactory.insert(:category, workspace_id: workspace.id, position: "n")

      assert {:error, :prev_must_be_less_than_next} =
               RepositionCategory.call(scope, cat3.external_id, cat1.external_id, cat2.external_id)
    end

    test "broadcasts category_repositioned event on success", %{workspace: workspace, cat1: cat1, cat2: cat2, cat3: cat3} do
      user = IdentityFactory.insert(:user)
      CoreFactory.insert(:workspace_user, workspace_id: workspace.id, user_id: user.id, role: :owner)
      scope = IdentityFactory.build(:scope, user: user)

      expect(BroadcastWorkspace, :call, fn received_workspace, {:category_repositioned, received_category} ->
        assert received_workspace.id == workspace.id
        assert received_category.id == cat3.id
        :ok
      end)

      assert {:ok, _updated} = RepositionCategory.call(scope, cat3.external_id, cat1.external_id, cat2.external_id)

      verify!()
    end

    test "handles unique constraint violation with retry", %{workspace: workspace, cat1: cat1, cat2: cat2, cat3: cat3} do
      user = IdentityFactory.insert(:user)
      CoreFactory.insert(:workspace_user, workspace_id: workspace.id, user_id: user.id, role: :owner)
      scope = IdentityFactory.build(:scope, user: user)

      assert {:ok, updated} = RepositionCategory.call(scope, cat3.external_id, cat1.external_id, cat2.external_id)

      assert updated.id == cat3.id
      assert updated.position > cat1.position
      assert updated.position < cat2.position
    end

    test "returns error after max retries", %{workspace: workspace, cat1: cat1, cat2: cat2, cat3: cat3} do
      user = IdentityFactory.insert(:user)
      CoreFactory.insert(:workspace_user, workspace_id: workspace.id, user_id: user.id, role: :owner)
      scope = IdentityFactory.build(:scope, user: user)

      stub(CategoryRepository, :update_position, fn _category, _position ->
        changeset = Category.position_changeset(cat3, %{position: "test"})
        changeset = Ecto.Changeset.add_error(changeset, :position, "has already been taken")
        {:error, changeset}
      end)

      assert {:error, changeset} = RepositionCategory.call(scope, cat3.external_id, cat1.external_id, cat2.external_id)

      assert Enum.any?(changeset.errors, fn
               {:position, {"has already been taken", _opts}} -> true
               _error -> false
             end)
    end

    test "handles non-position errors in changeset", %{workspace: workspace, cat1: cat1, cat2: cat2, cat3: cat3} do
      user = IdentityFactory.insert(:user)
      CoreFactory.insert(:workspace_user, workspace_id: workspace.id, user_id: user.id, role: :owner)
      scope = IdentityFactory.build(:scope, user: user)

      stub(CategoryRepository, :update_position, fn _category, _position ->
        changeset = Category.position_changeset(cat3, %{position: "test"})
        changeset = Ecto.Changeset.add_error(changeset, :name, "is invalid")
        {:error, changeset}
      end)

      assert {:error, changeset} = RepositionCategory.call(scope, cat3.external_id, cat1.external_id, cat2.external_id)

      refute Enum.any?(changeset.errors, fn
               {:position, {"has already been taken", _opts}} -> true
               _error -> false
             end)
    end
  end
end

defmodule PurseCraft.Budgeting.Commands.Categories.ChangeCategoryTest do
  use PurseCraft.DataCase, async: true

  alias PurseCraft.Budgeting.Commands.Categories.ChangeCategory
  alias PurseCraft.BudgetingFactory
  alias PurseCraft.CoreFactory

  describe "call/2" do
    test "returns a category changeset" do
      workspace = CoreFactory.insert(:workspace)
      category = BudgetingFactory.insert(:category, workspace_id: workspace.id)

      assert %Ecto.Changeset{} = changeset = ChangeCategory.call(category, %{})
      assert changeset.data == category
      assert changeset.changes == %{}
    end

    test "returns a category changeset with changes" do
      workspace = CoreFactory.insert(:workspace)
      category = BudgetingFactory.insert(:category, workspace_id: workspace.id)
      new_name = "New Category Name"

      assert %Ecto.Changeset{} = changeset = ChangeCategory.call(category, %{name: new_name})
      assert changeset.data == category
      assert changeset.changes == %{name: new_name, name_hash: new_name}
    end
  end
end

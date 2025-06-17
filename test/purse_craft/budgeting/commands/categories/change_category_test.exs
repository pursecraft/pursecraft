defmodule PurseCraft.Budgeting.Commands.Categories.ChangeCategoryTest do
  use PurseCraft.DataCase, async: true

  alias PurseCraft.Budgeting.Commands.Categories.ChangeCategory
  alias PurseCraft.BudgetingFactory

  describe "call/2" do
    test "returns a category changeset" do
      book = BudgetingFactory.insert(:book)
      category = BudgetingFactory.insert(:category, book_id: book.id)

      assert %Ecto.Changeset{} = changeset = ChangeCategory.call(category, %{})
      assert changeset.data == category
      assert changeset.changes == %{}
    end

    test "returns a category changeset with changes" do
      book = BudgetingFactory.insert(:book)
      category = BudgetingFactory.insert(:category, book_id: book.id)
      new_name = "New Category Name"

      assert %Ecto.Changeset{} = changeset = ChangeCategory.call(category, %{name: new_name})
      assert changeset.data == category
      assert changeset.changes == %{name: new_name, name_hash: new_name}
    end
  end
end

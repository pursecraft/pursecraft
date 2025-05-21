defmodule PurseCraft.Budgeting.Repositories.CategoryRepositoryTest do
  use PurseCraft.DataCase, async: true

  alias PurseCraft.Budgeting.Repositories.CategoryRepository
  alias PurseCraft.Budgeting.Schemas.Category
  alias PurseCraft.BudgetingFactory

  describe "delete/1" do
    test "deletes the given category" do
      book = BudgetingFactory.insert(:book)
      category = BudgetingFactory.insert(:category, book_id: book.id)

      assert {:ok, %Category{}} = CategoryRepository.delete(category)
      assert_raise Ecto.NoResultsError, fn -> Repo.get!(Category, category.id) end
    end
  end
end

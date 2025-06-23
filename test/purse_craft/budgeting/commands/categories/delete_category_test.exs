defmodule PurseCraft.Budgeting.Commands.Categories.DeleteCategoryTest do
  use PurseCraft.DataCase, async: true

  import Mimic

  alias PurseCraft.Budgeting.Commands.Categories.DeleteCategory
  alias PurseCraft.Budgeting.Schemas.Category
  alias PurseCraft.BudgetingFactory
  alias PurseCraft.CoreFactory
  alias PurseCraft.IdentityFactory
  alias PurseCraft.PubSub.BroadcastBook

  setup do
    book = CoreFactory.insert(:book)
    category = BudgetingFactory.insert(:category, book_id: book.id)

    %{
      book: book,
      category: category
    }
  end

  describe "call/3" do
    test "with owner role (authorized scope) deletes a category", %{book: book, category: category} do
      user = IdentityFactory.insert(:user)
      CoreFactory.insert(:book_user, book_id: book.id, user_id: user.id, role: :owner)
      scope = IdentityFactory.build(:scope, user: user)

      assert {:ok, %Category{}} = DeleteCategory.call(scope, book, category)
      assert_raise Ecto.NoResultsError, fn -> Repo.get!(Category, category.id) end
    end

    test "with editor role (authorized scope) deletes a category", %{book: book, category: category} do
      user = IdentityFactory.insert(:user)
      CoreFactory.insert(:book_user, book_id: book.id, user_id: user.id, role: :editor)
      scope = IdentityFactory.build(:scope, user: user)

      assert {:ok, %Category{}} = DeleteCategory.call(scope, book, category)
      assert_raise Ecto.NoResultsError, fn -> Repo.get!(Category, category.id) end
    end

    test "with commenter role (unauthorized scope) returns error", %{book: book, category: category} do
      user = IdentityFactory.insert(:user)
      CoreFactory.insert(:book_user, book_id: book.id, user_id: user.id, role: :commenter)
      scope = IdentityFactory.build(:scope, user: user)

      assert {:error, :unauthorized} = DeleteCategory.call(scope, book, category)
      assert Repo.get(Category, category.id)
    end

    test "with no association to book (unauthorized scope) returns error", %{book: book, category: category} do
      user = IdentityFactory.insert(:user)
      scope = IdentityFactory.build(:scope, user: user)

      assert {:error, :unauthorized} = DeleteCategory.call(scope, book, category)
      assert Repo.get(Category, category.id)
    end

    test "invokes BroadcastBook when category is deleted successfully", %{book: book, category: category} do
      user = IdentityFactory.insert(:user)
      CoreFactory.insert(:book_user, book_id: book.id, user_id: user.id, role: :owner)
      scope = IdentityFactory.build(:scope, user: user)

      expect(BroadcastBook, :call, fn broadcast_book, {:category_deleted, broadcast_category} ->
        assert broadcast_book == book
        assert broadcast_category.id == category.id
        :ok
      end)

      assert {:ok, %Category{}} = DeleteCategory.call(scope, book, category)

      verify!()
    end
  end
end

defmodule PurseCraft.Budgeting.Commands.Categories.ListCategoriesTest do
  use PurseCraft.DataCase, async: true

  alias PurseCraft.Budgeting.Commands.Categories.ListCategories
  alias PurseCraft.BudgetingFactory
  alias PurseCraft.IdentityFactory

  setup do
    user = IdentityFactory.insert(:user)
    book = IdentityFactory.insert(:book)
    IdentityFactory.insert(:book_user, book_id: book.id, user_id: user.id, role: :owner)
    scope = IdentityFactory.build(:scope, user: user)

    %{
      user: user,
      scope: scope,
      book: book
    }
  end

  describe "call/3" do
    setup %{book: book} do
      categories = Enum.map(["a", "b", "c"], &BudgetingFactory.insert(:category, book_id: book.id, position: &1))

      other_book = IdentityFactory.insert(:book)
      other_category = BudgetingFactory.insert(:category, book_id: other_book.id, position: "d")

      %{categories: categories, other_book: other_book, other_category: other_category}
    end

    test "with associated book (authorized scope) returns all book categories", %{
      scope: scope,
      book: book,
      categories: categories
    } do
      result = ListCategories.call(scope, book)

      sorted_result = Enum.sort_by(result, & &1.id)
      sorted_categories = Enum.sort_by(categories, & &1.id)

      assert length(sorted_result) == length(sorted_categories)

      sorted_result
      |> Enum.zip(sorted_categories)
      |> Enum.each(fn {result_cat, expected_cat} ->
        assert result_cat.id == expected_cat.id
        assert result_cat.name == expected_cat.name
        assert result_cat.external_id == expected_cat.external_id
        assert result_cat.book_id == book.id
      end)
    end

    test "with associated book and preload option returns categories with associations", %{
      scope: scope,
      book: book,
      categories: categories
    } do
      category = List.first(categories)
      envelope = BudgetingFactory.insert(:envelope, category_id: category.id)

      result = ListCategories.call(scope, book, preload: [:envelopes])

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
      book: book,
      categories: categories
    } do
      user = IdentityFactory.insert(:user)
      IdentityFactory.insert(:book_user, book_id: book.id, user_id: user.id, role: :editor)
      scope = IdentityFactory.build(:scope, user: user)

      result = ListCategories.call(scope, book)
      assert length(result) == length(categories)
    end

    test "with commenter role (authorized scope) returns categories", %{
      book: book,
      categories: categories
    } do
      user = IdentityFactory.insert(:user)
      IdentityFactory.insert(:book_user, book_id: book.id, user_id: user.id, role: :commenter)
      scope = IdentityFactory.build(:scope, user: user)

      result = ListCategories.call(scope, book)
      assert length(result) == length(categories)
    end

    test "with no association to book (unauthorized scope) returns error", %{
      book: book
    } do
      user = IdentityFactory.insert(:user)
      scope = IdentityFactory.build(:scope, user: user)

      assert {:error, :unauthorized} = ListCategories.call(scope, book)
    end

    test "returns only categories for the specified book", %{
      scope: scope,
      book: book,
      categories: categories,
      other_book: other_book,
      other_category: other_category
    } do
      IdentityFactory.insert(:book_user, book_id: other_book.id, user_id: scope.user.id, role: :owner)

      book_categories = ListCategories.call(scope, book)
      assert length(book_categories) == length(categories)
      assert Enum.all?(book_categories, fn cat -> cat.book_id == book.id end)

      other_book_categories = ListCategories.call(scope, other_book)
      assert length(other_book_categories) == 1
      assert hd(other_book_categories).id == other_category.id
    end
  end
end

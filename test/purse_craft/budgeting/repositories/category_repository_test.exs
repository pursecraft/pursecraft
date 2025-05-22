defmodule PurseCraft.Budgeting.Repositories.CategoryRepositoryTest do
  use PurseCraft.DataCase, async: true

  alias PurseCraft.Budgeting.Repositories.CategoryRepository
  alias PurseCraft.Budgeting.Schemas.Category
  alias PurseCraft.BudgetingFactory

  describe "list_by_book_id/2" do
    test "returns all categories for a given book" do
      book = BudgetingFactory.insert(:book)
      categories = for _index <- 1..3, do: BudgetingFactory.insert(:category, book_id: book.id)

      other_book = BudgetingFactory.insert(:book)
      BudgetingFactory.insert(:category, book_id: other_book.id)

      result = CategoryRepository.list_by_book_id(book.id)

      assert length(result) == 3
      assert Enum.all?(result, fn cat -> cat.book_id == book.id end)

      result_ids =
        result
        |> Enum.map(& &1.id)
        |> Enum.sort()

      expected_ids =
        categories
        |> Enum.map(& &1.id)
        |> Enum.sort()

      assert result_ids == expected_ids
    end

    test "returns empty list when no categories exist for book" do
      book = BudgetingFactory.insert(:book)

      result = CategoryRepository.list_by_book_id(book.id)

      assert result == []
    end

    test "with preload option returns categories with preloaded associations" do
      book = BudgetingFactory.insert(:book)
      category = BudgetingFactory.insert(:category, book_id: book.id)
      envelope = BudgetingFactory.insert(:envelope, category_id: category.id)

      result = CategoryRepository.list_by_book_id(book.id, preload: [:envelopes])

      assert length(result) == 1
      category_result = hd(result)
      assert length(category_result.envelopes) == 1
      assert hd(category_result.envelopes).id == envelope.id
    end

    test "without preload option returns categories without preloaded associations" do
      book = BudgetingFactory.insert(:book)
      category = BudgetingFactory.insert(:category, book_id: book.id)
      BudgetingFactory.insert(:envelope, category_id: category.id)

      result = CategoryRepository.list_by_book_id(book.id)

      assert length(result) == 1
      category_result = hd(result)
      refute Ecto.assoc_loaded?(category_result.envelopes)
    end
  end

  describe "get_by_external_id_and_book_id/3" do
    test "returns category when found" do
      book = BudgetingFactory.insert(:book)
      category = BudgetingFactory.insert(:category, book_id: book.id)

      result = CategoryRepository.get_by_external_id_and_book_id(category.external_id, book.id)

      assert result.id == category.id
      assert result.name == category.name
      assert result.book_id == book.id
    end

    test "returns nil when category not found by external_id" do
      book = BudgetingFactory.insert(:book)

      result = CategoryRepository.get_by_external_id_and_book_id(Ecto.UUID.generate(), book.id)

      assert result == nil
    end

    test "returns nil when category not found by book_id" do
      book1 = BudgetingFactory.insert(:book)
      book2 = BudgetingFactory.insert(:book)
      category = BudgetingFactory.insert(:category, book_id: book1.id)

      result = CategoryRepository.get_by_external_id_and_book_id(category.external_id, book2.id)

      assert result == nil
    end

    test "with preload option returns category with preloaded associations" do
      book = BudgetingFactory.insert(:book)
      category = BudgetingFactory.insert(:category, book_id: book.id)
      envelope = BudgetingFactory.insert(:envelope, category_id: category.id)

      result = CategoryRepository.get_by_external_id_and_book_id(category.external_id, book.id, preload: [:envelopes])

      assert result.id == category.id
      assert length(result.envelopes) == 1
      assert hd(result.envelopes).id == envelope.id
    end

    test "without preload option returns category without preloaded associations" do
      book = BudgetingFactory.insert(:book)
      category = BudgetingFactory.insert(:category, book_id: book.id)
      BudgetingFactory.insert(:envelope, category_id: category.id)

      result = CategoryRepository.get_by_external_id_and_book_id(category.external_id, book.id)

      assert result.id == category.id
      refute Ecto.assoc_loaded?(result.envelopes)
    end
  end

  describe "delete/1" do
    test "deletes the given category" do
      book = BudgetingFactory.insert(:book)
      category = BudgetingFactory.insert(:category, book_id: book.id)

      assert {:ok, %Category{}} = CategoryRepository.delete(category)
      assert_raise Ecto.NoResultsError, fn -> Repo.get!(Category, category.id) end
    end
  end
end

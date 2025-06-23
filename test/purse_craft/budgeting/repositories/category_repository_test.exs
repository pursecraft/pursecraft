defmodule PurseCraft.Budgeting.Repositories.CategoryRepositoryTest do
  use PurseCraft.DataCase, async: true

  alias PurseCraft.Budgeting.Repositories.CategoryRepository
  alias PurseCraft.Budgeting.Schemas.Category
  alias PurseCraft.BudgetingFactory
  alias PurseCraft.CoreFactory

  describe "list_by_book_id/2" do
    test "returns all categories for a given book" do
      book = CoreFactory.insert(:book)
      categories = for _index <- 1..3, do: BudgetingFactory.insert(:category, book_id: book.id)

      other_book = CoreFactory.insert(:book)
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
      book = CoreFactory.insert(:book)

      result = CategoryRepository.list_by_book_id(book.id)

      assert result == []
    end

    test "with preload option returns categories with preloaded associations" do
      book = CoreFactory.insert(:book)
      category = BudgetingFactory.insert(:category, book_id: book.id)
      envelope = BudgetingFactory.insert(:envelope, category_id: category.id)

      result = CategoryRepository.list_by_book_id(book.id, preload: [:envelopes])

      assert length(result) == 1
      category_result = hd(result)
      assert length(category_result.envelopes) == 1
      assert hd(category_result.envelopes).id == envelope.id
    end

    test "with preload option returns envelopes ordered by position" do
      book = CoreFactory.insert(:book)
      category = BudgetingFactory.insert(:category, book_id: book.id)

      env1 = BudgetingFactory.insert(:envelope, category_id: category.id, position: "s")
      env2 = BudgetingFactory.insert(:envelope, category_id: category.id, position: "a")
      env3 = BudgetingFactory.insert(:envelope, category_id: category.id, position: "z")

      result = CategoryRepository.list_by_book_id(book.id, preload: [:envelopes])

      assert length(result) == 1
      category_result = hd(result)
      assert length(category_result.envelopes) == 3

      envelope_positions = Enum.map(category_result.envelopes, & &1.position)
      assert envelope_positions == ["a", "s", "z"]

      envelope_ids = Enum.map(category_result.envelopes, & &1.id)
      assert envelope_ids == [env2.id, env1.id, env3.id]
    end

    test "without preload option returns categories without preloaded associations" do
      book = CoreFactory.insert(:book)
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
      book = CoreFactory.insert(:book)
      category = BudgetingFactory.insert(:category, book_id: book.id)

      result = CategoryRepository.get_by_external_id_and_book_id(category.external_id, book.id)

      assert result.id == category.id
      assert result.name == category.name
      assert result.book_id == book.id
    end

    test "returns nil when category not found by external_id" do
      book = CoreFactory.insert(:book)

      result = CategoryRepository.get_by_external_id_and_book_id(Ecto.UUID.generate(), book.id)

      assert result == nil
    end

    test "returns nil when category not found by book_id" do
      book1 = CoreFactory.insert(:book)
      book2 = CoreFactory.insert(:book)
      category = BudgetingFactory.insert(:category, book_id: book1.id)

      result = CategoryRepository.get_by_external_id_and_book_id(category.external_id, book2.id)

      assert result == nil
    end

    test "with preload option returns category with preloaded associations" do
      book = CoreFactory.insert(:book)
      category = BudgetingFactory.insert(:category, book_id: book.id)
      envelope = BudgetingFactory.insert(:envelope, category_id: category.id)

      result = CategoryRepository.get_by_external_id_and_book_id(category.external_id, book.id, preload: [:envelopes])

      assert result.id == category.id
      assert length(result.envelopes) == 1
      assert hd(result.envelopes).id == envelope.id
    end

    test "with preload option returns envelopes ordered by position" do
      book = CoreFactory.insert(:book)
      category = BudgetingFactory.insert(:category, book_id: book.id)

      env1 = BudgetingFactory.insert(:envelope, category_id: category.id, position: "m")
      env2 = BudgetingFactory.insert(:envelope, category_id: category.id, position: "b")
      env3 = BudgetingFactory.insert(:envelope, category_id: category.id, position: "x")

      result = CategoryRepository.get_by_external_id_and_book_id(category.external_id, book.id, preload: [:envelopes])

      assert result.id == category.id
      assert length(result.envelopes) == 3

      envelope_positions = Enum.map(result.envelopes, & &1.position)
      assert envelope_positions == ["b", "m", "x"]

      envelope_ids = Enum.map(result.envelopes, & &1.id)
      assert envelope_ids == [env2.id, env1.id, env3.id]
    end

    test "without preload option returns category without preloaded associations" do
      book = CoreFactory.insert(:book)
      category = BudgetingFactory.insert(:category, book_id: book.id)
      BudgetingFactory.insert(:envelope, category_id: category.id)

      result = CategoryRepository.get_by_external_id_and_book_id(category.external_id, book.id)

      assert result.id == category.id
      refute Ecto.assoc_loaded?(result.envelopes)
    end
  end

  describe "update/3" do
    test "updates the given category with valid attributes" do
      book = CoreFactory.insert(:book)
      category = BudgetingFactory.insert(:category, book_id: book.id, name: "Original Name")

      attrs = %{name: "Updated Name"}

      assert {:ok, %Category{} = updated_category} = CategoryRepository.update(category, attrs)
      assert updated_category.name == "Updated Name"
      assert updated_category.id == category.id
      assert updated_category.book_id == category.book_id
    end

    test "returns error changeset with invalid attributes" do
      book = CoreFactory.insert(:book)
      category = BudgetingFactory.insert(:category, book_id: book.id)

      attrs = %{name: ""}

      assert {:error, changeset} = CategoryRepository.update(category, attrs)
      assert %{name: ["can't be blank"]} = errors_on(changeset)
    end

    test "with preload option returns category with preloaded associations" do
      book = CoreFactory.insert(:book)
      category = BudgetingFactory.insert(:category, book_id: book.id, name: "Original Name")
      envelope = BudgetingFactory.insert(:envelope, category_id: category.id)

      attrs = %{name: "Updated Name"}

      assert {:ok, %Category{} = updated_category} = CategoryRepository.update(category, attrs, preload: [:envelopes])
      assert updated_category.name == "Updated Name"
      assert length(updated_category.envelopes) == 1
      assert hd(updated_category.envelopes).id == envelope.id
    end

    test "without preload option returns category without preloaded associations" do
      book = CoreFactory.insert(:book)
      category = BudgetingFactory.insert(:category, book_id: book.id, name: "Original Name")
      BudgetingFactory.insert(:envelope, category_id: category.id)

      attrs = %{name: "Updated Name"}

      assert {:ok, %Category{} = updated_category} = CategoryRepository.update(category, attrs)
      assert updated_category.name == "Updated Name"
      refute Ecto.assoc_loaded?(updated_category.envelopes)
    end
  end

  describe "delete/1" do
    test "deletes the given category" do
      book = CoreFactory.insert(:book)
      category = BudgetingFactory.insert(:category, book_id: book.id)

      assert {:ok, %Category{}} = CategoryRepository.delete(category)
      assert_raise Ecto.NoResultsError, fn -> Repo.get!(Category, category.id) end
    end
  end

  describe "get_first_position/1" do
    test "returns the position of the first category when categories exist" do
      book = CoreFactory.insert(:book)
      BudgetingFactory.insert(:category, book: book, position: "m")
      BudgetingFactory.insert(:category, book: book, position: "g")
      BudgetingFactory.insert(:category, book: book, position: "t")

      result = CategoryRepository.get_first_position(book.id)

      assert result == "g"
    end

    test "returns nil when no categories exist for the book" do
      book = CoreFactory.insert(:book)

      result = CategoryRepository.get_first_position(book.id)

      assert result == nil
    end
  end

  describe "list_by_external_ids/2" do
    test "returns categories matching the given external IDs" do
      book = CoreFactory.insert(:book)
      cat1 = BudgetingFactory.insert(:category, book_id: book.id, position: "g")
      cat2 = BudgetingFactory.insert(:category, book_id: book.id, position: "m")
      cat3 = BudgetingFactory.insert(:category, book_id: book.id, position: "t")

      BudgetingFactory.insert(:category, book_id: book.id, position: "z")

      external_ids = [cat1.external_id, cat2.external_id, cat3.external_id]
      result = CategoryRepository.list_by_external_ids(external_ids)

      assert length(result) == 3
      result_external_ids = Enum.map(result, & &1.external_id)
      assert Enum.all?(external_ids, &(&1 in result_external_ids))
    end

    test "returns empty list when no categories match the external IDs" do
      result = CategoryRepository.list_by_external_ids([Ecto.UUID.generate(), Ecto.UUID.generate()])

      assert result == []
    end

    test "returns subset when only some external IDs match" do
      book = CoreFactory.insert(:book)
      cat1 = BudgetingFactory.insert(:category, book_id: book.id, position: "g")

      external_ids = [cat1.external_id, Ecto.UUID.generate(), Ecto.UUID.generate()]
      result = CategoryRepository.list_by_external_ids(external_ids)

      assert length(result) == 1
      assert hd(result).external_id == cat1.external_id
    end

    test "with preload option returns categories with preloaded associations" do
      book = CoreFactory.insert(:book)
      cat1 = BudgetingFactory.insert(:category, book_id: book.id, position: "g")
      cat2 = BudgetingFactory.insert(:category, book_id: book.id, position: "m")

      envelope1 = BudgetingFactory.insert(:envelope, category_id: cat1.id)
      envelope2 = BudgetingFactory.insert(:envelope, category_id: cat2.id)

      external_ids = [cat1.external_id, cat2.external_id]
      result = CategoryRepository.list_by_external_ids(external_ids, preload: [:envelopes])

      assert length(result) == 2

      cat1_result = Enum.find(result, &(&1.external_id == cat1.external_id))
      cat2_result = Enum.find(result, &(&1.external_id == cat2.external_id))

      assert length(cat1_result.envelopes) == 1
      assert hd(cat1_result.envelopes).id == envelope1.id
      assert length(cat2_result.envelopes) == 1
      assert hd(cat2_result.envelopes).id == envelope2.id
    end

    test "handles empty list of external IDs" do
      result = CategoryRepository.list_by_external_ids([])

      assert result == []
    end
  end

  describe "update_position/2" do
    test "updates the position of a category with valid position" do
      book = CoreFactory.insert(:book)
      category = BudgetingFactory.insert(:category, book_id: book.id, position: "g")

      assert {:ok, updated_category} = CategoryRepository.update_position(category, "m")
      assert updated_category.position == "m"
      assert updated_category.id == category.id
      assert updated_category.name == category.name
    end

    test "returns error changeset with invalid position format" do
      book = CoreFactory.insert(:book)
      category = BudgetingFactory.insert(:category, book_id: book.id, position: "g")

      assert {:error, changeset} = CategoryRepository.update_position(category, "ABC")
      assert %{position: ["must contain only lowercase letters"]} = errors_on(changeset)
    end

    test "returns error changeset with empty position" do
      book = CoreFactory.insert(:book)
      category = BudgetingFactory.insert(:category, book_id: book.id, position: "g")

      assert {:error, changeset} = CategoryRepository.update_position(category, "")
      assert %{position: ["can't be blank"]} = errors_on(changeset)
    end

    test "returns error changeset when position violates unique constraint" do
      book = CoreFactory.insert(:book)
      BudgetingFactory.insert(:category, book_id: book.id, position: "g")
      cat2 = BudgetingFactory.insert(:category, book_id: book.id, position: "m")

      assert {:error, changeset} = CategoryRepository.update_position(cat2, "g")
      assert %{position: ["has already been taken"]} = errors_on(changeset)
    end

    test "allows same position in different books" do
      book1 = CoreFactory.insert(:book)
      book2 = CoreFactory.insert(:book)
      BudgetingFactory.insert(:category, book_id: book1.id, position: "g")
      cat2 = BudgetingFactory.insert(:category, book_id: book2.id, position: "m")

      assert {:ok, updated_category} = CategoryRepository.update_position(cat2, "g")
      assert updated_category.position == "g"
    end
  end

  describe "fetch/2" do
    test "returns {:ok, category} when found" do
      book = CoreFactory.insert(:book)
      category = BudgetingFactory.insert(:category, book_id: book.id)

      assert {:ok, result} = CategoryRepository.fetch(category.id)
      assert result.id == category.id
      assert result.name == category.name
      assert result.book_id == book.id
    end

    test "returns {:error, :not_found} when category not found" do
      assert {:error, :not_found} = CategoryRepository.fetch(999)
    end

    test "with preload option returns category with preloaded associations" do
      book = CoreFactory.insert(:book)
      category = BudgetingFactory.insert(:category, book_id: book.id)
      envelope = BudgetingFactory.insert(:envelope, category_id: category.id)

      assert {:ok, result} = CategoryRepository.fetch(category.id, preload: [:envelopes])
      assert result.id == category.id
      assert length(result.envelopes) == 1
      assert hd(result.envelopes).id == envelope.id
    end

    test "without preload option returns category without preloaded associations" do
      book = CoreFactory.insert(:book)
      category = BudgetingFactory.insert(:category, book_id: book.id)
      BudgetingFactory.insert(:envelope, category_id: category.id)

      assert {:ok, result} = CategoryRepository.fetch(category.id)
      assert result.id == category.id
      refute Ecto.assoc_loaded?(result.envelopes)
    end
  end
end

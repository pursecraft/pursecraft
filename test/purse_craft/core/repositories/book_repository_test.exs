defmodule PurseCraft.Core.Repositories.BookRepositoryTest do
  use PurseCraft.DataCase, async: true

  alias PurseCraft.BudgetingFactory
  alias PurseCraft.Core.Repositories.BookRepository
  alias PurseCraft.Core.Schemas.Book
  alias PurseCraft.Core.Schemas.BookUser
  alias PurseCraft.IdentityFactory
  alias PurseCraft.Repo

  describe "list_by_user/1" do
    test "returns all books associated with a user" do
      user = IdentityFactory.insert(:user)
      book = BudgetingFactory.insert(:book)
      BudgetingFactory.insert(:book_user, book_id: book.id, user_id: user.id, role: :owner)

      other_user = IdentityFactory.insert(:user)
      other_book = BudgetingFactory.insert(:book)
      BudgetingFactory.insert(:book_user, book_id: other_book.id, user_id: other_user.id)

      result = BookRepository.list_by_user(user.id)
      assert [returned_book] = result
      assert returned_book.id == book.id
      assert returned_book.external_id == book.external_id
      assert returned_book.name == book.name

      other_result = BookRepository.list_by_user(other_user.id)
      assert [returned_other_book] = other_result
      assert returned_other_book.id == other_book.id
      assert returned_other_book.external_id == other_book.external_id
      assert returned_other_book.name == other_book.name
    end

    test "with no associated books returns empty list" do
      user = IdentityFactory.insert(:user)

      assert BookRepository.list_by_user(user.id) == []
    end
  end

  describe "get_by_external_id!/1" do
    test "with existing book returns the book" do
      book = BudgetingFactory.insert(:book)

      result = BookRepository.get_by_external_id!(book.external_id)
      assert result.id == book.id
      assert result.external_id == book.external_id
      assert result.name == book.name
    end

    test "with non-existent book raises Ecto.NoResultsError" do
      assert_raise Ecto.NoResultsError, fn ->
        non_existent_id = Ecto.UUID.generate()

        BookRepository.get_by_external_id!(non_existent_id)
      end
    end
  end

  describe "get_by_external_id/1" do
    test "with existing book returns the book" do
      book = BudgetingFactory.insert(:book)

      result = BookRepository.get_by_external_id(book.external_id)
      assert result.id == book.id
      assert result.external_id == book.external_id
      assert result.name == book.name
    end

    test "with non-existent book returns nil" do
      non_existent_id = Ecto.UUID.generate()

      assert BookRepository.get_by_external_id(non_existent_id) == nil
    end
  end

  describe "get_by_external_id/2" do
    test "with existing book returns the book" do
      book = BudgetingFactory.insert(:book)

      result = BookRepository.get_by_external_id(book.external_id)
      assert result.id == book.id
      assert result.external_id == book.external_id
      assert result.name == book.name
    end

    test "with non-existent book returns nil" do
      non_existent_id = Ecto.UUID.generate()

      assert BookRepository.get_by_external_id(non_existent_id) == nil
    end

    test "with preload option loads the association" do
      book = BudgetingFactory.insert(:book)
      category1 = BudgetingFactory.insert(:category, book_id: book.id, position: "g")
      category2 = BudgetingFactory.insert(:category, book_id: book.id, position: "h")

      book_with_categories = BookRepository.get_by_external_id(book.external_id, preload: [:categories])

      assert Enum.count(book_with_categories.categories) == 2
      assert Enum.any?(book_with_categories.categories, &(&1.id == category1.id))
      assert Enum.any?(book_with_categories.categories, &(&1.id == category2.id))
    end

    test "with empty preload list returns the book without preloading" do
      book = BudgetingFactory.insert(:book)
      BudgetingFactory.insert(:category, book_id: book.id, position: "g")

      book_without_preload = BookRepository.get_by_external_id(book.external_id, preload: [])

      assert book_without_preload.id == book.id
      assert match?(%Ecto.Association.NotLoaded{}, book_without_preload.categories)
    end
  end

  describe "create/2" do
    test "with valid data creates a book and associates it with a user" do
      user = IdentityFactory.insert(:user)
      attrs = %{name: "Test Book"}

      assert {:ok, book} = BookRepository.create(attrs, user.id)
      assert book.name == "Test Book"

      book_user = PurseCraft.Repo.get_by(PurseCraft.Core.Schemas.BookUser, book_id: book.id)
      assert book_user.user_id == user.id
      assert book_user.role == :owner
    end

    test "with invalid data returns error changeset" do
      user = IdentityFactory.insert(:user)
      attrs = %{name: ""}

      assert {:error, changeset} = BookRepository.create(attrs, user.id)
      assert %{name: ["can't be blank"]} = errors_on(changeset)
    end
  end

  describe "update/2" do
    test "with valid data updates the book" do
      book = BudgetingFactory.insert(:book, name: "Original Name")
      attrs = %{name: "Updated Name"}

      assert {:ok, updated_book} = BookRepository.update(book, attrs)
      assert updated_book.name == "Updated Name"
      assert updated_book.id == book.id
      assert updated_book.external_id == book.external_id
    end

    test "with invalid data returns error changeset" do
      book = BudgetingFactory.insert(:book, name: "Original Name")
      attrs = %{name: ""}

      assert {:error, changeset} = BookRepository.update(book, attrs)
      assert %{name: ["can't be blank"]} = errors_on(changeset)

      reloaded_book = Repo.get(Book, book.id)
      assert reloaded_book.name == "Original Name"
    end
  end

  describe "delete/1" do
    test "deletes the book successfully" do
      book = BudgetingFactory.insert(:book)

      assert {:ok, deleted_book} = BookRepository.delete(book)
      assert deleted_book.id == book.id
      assert Repo.get(Book, book.id) == nil
    end

    test "deletes associated book_user records" do
      book = BudgetingFactory.insert(:book)
      user1 = IdentityFactory.insert(:user)
      user2 = IdentityFactory.insert(:user)

      book_user1 = BudgetingFactory.insert(:book_user, book_id: book.id, user_id: user1.id, role: :owner)
      book_user2 = BudgetingFactory.insert(:book_user, book_id: book.id, user_id: user2.id, role: :editor)

      assert {:ok, _deleted_book} = BookRepository.delete(book)

      assert Repo.get(Book, book.id) == nil
      assert Repo.get(BookUser, book_user1.id) == nil
      assert Repo.get(BookUser, book_user2.id) == nil
    end
  end
end

defmodule PurseCraft.Budgeting.Repositories.BookRepositoryTest do
  use PurseCraft.DataCase, async: true

  alias PurseCraft.Budgeting.Repositories.BookRepository
  alias PurseCraft.BudgetingFactory
  alias PurseCraft.IdentityFactory

  describe "list_by_user/1" do
    test "returns all books associated with a user" do
      user = IdentityFactory.insert(:user)
      book = BudgetingFactory.insert(:book)
      BudgetingFactory.insert(:book_user, book_id: book.id, user_id: user.id, role: :owner)

      other_user = IdentityFactory.insert(:user)
      other_book = BudgetingFactory.insert(:book)
      BudgetingFactory.insert(:book_user, book_id: other_book.id, user_id: other_user.id)

      assert BookRepository.list_by_user(user.id) == [book]
      assert BookRepository.list_by_user(other_user.id) == [other_book]
    end

    test "with no associated books returns empty list" do
      user = IdentityFactory.insert(:user)

      assert BookRepository.list_by_user(user.id) == []
    end
  end

  describe "get_by_external_id!/1" do
    test "with existing book returns the book" do
      book = BudgetingFactory.insert(:book)

      assert BookRepository.get_by_external_id!(book.external_id) == book
    end

    test "with non-existent book raises Ecto.NoResultsError" do
      assert_raise Ecto.NoResultsError, fn ->
        non_existent_id = Ecto.UUID.generate()

        BookRepository.get_by_external_id!(non_existent_id)
      end
    end
  end
end

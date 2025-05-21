defmodule PurseCraft.Budgeting.Commands.Books.ListBooksTest do
  use PurseCraft.DataCase, async: true

  alias PurseCraft.Budgeting.Commands.Books.ListBooks
  alias PurseCraft.BudgetingFactory
  alias PurseCraft.IdentityFactory

  describe "call/1" do
    test "with associated books returns all scoped books" do
      user = IdentityFactory.insert(:user)
      scope = IdentityFactory.build(:scope, user: user)
      book = BudgetingFactory.insert(:book)
      BudgetingFactory.insert(:book_user, book_id: book.id, user_id: user.id, role: :owner)

      other_user = IdentityFactory.insert(:user)
      other_scope = IdentityFactory.build(:scope, user: other_user)
      other_book = BudgetingFactory.insert(:book)
      BudgetingFactory.insert(:book_user, book_id: other_book.id, user_id: other_user.id)

      assert ListBooks.call(scope) == [book]
      assert ListBooks.call(other_scope) == [other_book]
    end

    test "with no associated books returns empty list" do
      user = IdentityFactory.insert(:user)
      scope = IdentityFactory.build(:scope, user: user)

      assert ListBooks.call(scope) == []
    end
  end
end

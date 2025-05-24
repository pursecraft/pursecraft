defmodule PurseCraft.Budgeting.Queries.BookQueryTest do
  use PurseCraft.DataCase, async: true

  alias PurseCraft.Budgeting.Queries.BookQuery
  alias PurseCraft.BudgetingFactory
  alias PurseCraft.IdentityFactory
  alias PurseCraft.Repo

  describe "by_user/1" do
    test "returns a query for books associated with a user" do
      user = IdentityFactory.insert(:user)
      book = BudgetingFactory.insert(:book)
      BudgetingFactory.insert(:book_user, book_id: book.id, user_id: user.id, role: :owner)

      other_user = IdentityFactory.insert(:user)
      other_book = BudgetingFactory.insert(:book)
      BudgetingFactory.insert(:book_user, book_id: other_book.id, user_id: other_user.id)

      assert user.id
             |> BookQuery.by_user()
             |> Repo.all() == [book]

      assert other_user.id
             |> BookQuery.by_user()
             |> Repo.all() == [other_book]
    end

    test "with no associated books returns empty list" do
      user = IdentityFactory.insert(:user)

      assert user.id
             |> BookQuery.by_user()
             |> Repo.all() == []
    end
  end
end

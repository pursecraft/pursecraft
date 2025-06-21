defmodule PurseCraft.Budgeting.Queries.BookQueryTest do
  use PurseCraft.DataCase, async: true

  alias PurseCraft.Budgeting.Queries.BookQuery
  alias PurseCraft.Identity.Schemas.Book
  alias PurseCraft.Identity.Schemas.BookUser

  describe "by_user/1" do
    test "creates a query with join and filter by user_id" do
      user_id = 123
      query = BookQuery.by_user(user_id)

      assert query.from.source == {"books", Book}

      assert length(query.joins) == 1
      [join] = query.joins
      assert join.source == {nil, BookUser}

      assert length(query.wheres) == 1
      [where_clause] = query.wheres
      assert where_clause.params == [{user_id, {1, :user_id}}]
    end
  end

  describe "by_external_id/1" do
    test "creates a query filtered by external_id" do
      external_id = "test-uuid-123"
      query = BookQuery.by_external_id(external_id)

      assert query.from.source == {"books", Book}

      assert length(query.wheres) == 1

      [where_clause] = query.wheres
      assert where_clause.params == [{external_id, {0, :external_id}}]
    end
  end

  describe "book_users_by_book_id/1" do
    test "creates a query filtered by book_id" do
      book_id = 456
      query = BookQuery.book_users_by_book_id(book_id)

      assert query.from.source == {"books_users", BookUser}

      assert length(query.wheres) == 1

      [where_clause] = query.wheres
      assert where_clause.params == [{book_id, {0, :book_id}}]
    end
  end
end

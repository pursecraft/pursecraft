defmodule PurseCraft.Core.Queries.BookUserQueryTest do
  use PurseCraft.DataCase, async: true

  alias PurseCraft.Core.Queries.BookUserQuery
  alias PurseCraft.Core.Schemas.BookUser

  describe "by_book_id/1" do
    test "creates a query filtered by book_id" do
      book_id = 456
      query = BookUserQuery.by_book_id(book_id)

      assert query.from.source == {"books_users", BookUser}

      assert length(query.wheres) == 1

      [where_clause] = query.wheres
      assert where_clause.params == [{book_id, {0, :book_id}}]
    end
  end
end

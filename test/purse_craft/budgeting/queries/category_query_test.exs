defmodule PurseCraft.Budgeting.Queries.CategoryQueryTest do
  use PurseCraft.DataCase, async: true

  import Ecto.Query

  alias PurseCraft.Budgeting.Queries.CategoryQuery
  alias PurseCraft.Budgeting.Schemas.Category

  describe "by_external_id/1" do
    test "creates a query filtered by external_id" do
      external_id = "test-uuid-123"
      query = CategoryQuery.by_external_id(external_id)

      assert query.from.source == {"categories", Category}

      assert length(query.wheres) == 1

      [where_clause] = query.wheres
      assert where_clause.params == [{external_id, {0, :external_id}}]
    end
  end

  describe "by_external_id/2" do
    test "adds external_id filter to existing query" do
      base_query = from(c in Category, where: c.name == "Test")

      query = CategoryQuery.by_external_id(base_query, "test-id")

      assert length(query.wheres) == 2

      param_values = Enum.flat_map(query.wheres, & &1.params)
      assert {"test-id", {0, :external_id}} in param_values
    end

    test "preserves other query attributes" do
      base_query =
        from(c in Category,
          where: c.name == "Test",
          order_by: c.inserted_at,
          limit: 10
        )

      query = CategoryQuery.by_external_id(base_query, "test-id")

      assert query.limit.expr == 10
      assert length(query.order_bys) == 1
      assert length(query.wheres) == 2
    end
  end

  describe "by_book_id/1" do
    test "creates a query filtered by book_id" do
      book_id = 123
      query = CategoryQuery.by_book_id(book_id)

      assert query.from.source == {"categories", Category}

      assert length(query.wheres) == 1

      [where_clause] = query.wheres
      assert where_clause.params == [{book_id, {0, :book_id}}]
    end
  end

  describe "by_book_id/2" do
    test "adds book_id filter to existing query" do
      book_id = 456
      base_query = from(c in Category, where: c.name == "Food")

      query = CategoryQuery.by_book_id(base_query, book_id)

      assert length(query.wheres) == 2

      param_values = Enum.flat_map(query.wheres, & &1.params)
      assert {book_id, {0, :book_id}} in param_values
    end

    test "works with Category schema directly" do
      book_id = 789
      query = CategoryQuery.by_book_id(Category, book_id)

      assert query.from.source == {"categories", Category}
      assert length(query.wheres) == 1
      assert hd(query.wheres).params == [{book_id, {0, :book_id}}]
    end
  end

  describe "order_by_position/0" do
    test "creates a query ordered by position in ascending order" do
      query = CategoryQuery.order_by_position()

      assert query.from.source == {"categories", Category}
      assert length(query.order_bys) == 1

      [order_by] = query.order_bys
      assert order_by.expr == [asc: {{:., [], [{:&, [], [0]}, :position]}, [], []}]
    end
  end

  describe "order_by_position/1" do
    test "adds position ordering to existing query" do
      base_query = from(c in Category, where: c.book_id == 1)
      query = CategoryQuery.order_by_position(base_query)

      assert length(query.order_bys) == 1
      [order_by] = query.order_bys
      assert order_by.expr == [asc: {{:., [], [{:&, [], [0]}, :position]}, [], []}]
    end
  end

  describe "limit/1" do
    test "creates a query with limit" do
      count = 5
      query = CategoryQuery.limit(count)

      assert query.from.source == {"categories", Category}
      assert query.limit.expr == {:^, [], [0]}
      assert query.limit.params == [{5, :integer}]
    end
  end

  describe "limit/2" do
    test "adds limit to existing query" do
      base_query = from(c in Category, where: c.book_id == 1)
      count = 10
      query = CategoryQuery.limit(base_query, count)

      assert query.limit.expr == {:^, [], [0]}
      assert query.limit.params == [{10, :integer}]
    end
  end

  describe "select_position/0" do
    test "creates a query selecting only position field" do
      query = CategoryQuery.select_position()

      assert query.from.source == {"categories", Category}
      assert query.select.expr == {{:., [], [{:&, [], [0]}, :position]}, [], []}
    end
  end

  describe "select_position/1" do
    test "adds position selection to existing query" do
      base_query = from(c in Category, where: c.book_id == 1)
      query = CategoryQuery.select_position(base_query)

      assert query.select.expr == {{:., [], [{:&, [], [0]}, :position]}, [], []}
    end
  end
end

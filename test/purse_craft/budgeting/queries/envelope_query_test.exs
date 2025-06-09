defmodule PurseCraft.Budgeting.Queries.EnvelopeQueryTest do
  use PurseCraft.DataCase, async: true

  import Ecto.Query

  alias PurseCraft.Budgeting.Queries.EnvelopeQuery
  alias PurseCraft.Budgeting.Schemas.Category
  alias PurseCraft.Budgeting.Schemas.Envelope

  describe "by_external_id/1" do
    test "creates a query filtered by external_id" do
      external_id = "test-uuid-123"
      query = EnvelopeQuery.by_external_id(external_id)

      assert query.from.source == {"envelopes", Envelope}

      assert length(query.wheres) == 1

      [where_clause] = query.wheres
      assert where_clause.params == [{external_id, {0, :external_id}}]
    end
  end

  describe "by_external_id/2" do
    test "adds external_id filter to existing query" do
      base_query = from(e in Envelope, where: e.name == "Test")

      query = EnvelopeQuery.by_external_id(base_query, "test-id")

      assert length(query.wheres) == 2

      param_values = Enum.flat_map(query.wheres, & &1.params)
      assert {"test-id", {0, :external_id}} in param_values
    end

    test "preserves other query attributes" do
      base_query =
        from(e in Envelope,
          where: e.name == "Test",
          order_by: e.inserted_at,
          limit: 10
        )

      query = EnvelopeQuery.by_external_id(base_query, "test-id")

      assert query.limit.expr == 10
      assert length(query.order_bys) == 1
      assert length(query.wheres) == 2
    end
  end

  describe "by_book_id/1" do
    test "creates a query with join and filter by book_id" do
      book_id = 123
      query = EnvelopeQuery.by_book_id(book_id)

      assert query.from.source == {"envelopes", Envelope}

      assert length(query.joins) == 1
      [join] = query.joins
      assert join.source == {nil, Category}

      assert length(query.wheres) == 1
      [where_clause] = query.wheres
      assert where_clause.params == [{book_id, {1, :book_id}}]
    end
  end

  describe "by_book_id/2" do
    test "adds book_id filter with join to existing query" do
      book_id = 456
      base_query = from(e in Envelope, where: e.name == "Groceries")

      query = EnvelopeQuery.by_book_id(base_query, book_id)

      assert length(query.joins) == 1
      assert length(query.wheres) == 2

      param_values = Enum.flat_map(query.wheres, & &1.params)
      assert {book_id, {1, :book_id}} in param_values
    end

    test "works with Envelope schema directly" do
      book_id = 789
      query = EnvelopeQuery.by_book_id(Envelope, book_id)

      assert query.from.source == {"envelopes", Envelope}
      assert length(query.joins) == 1
      assert length(query.wheres) == 1
      assert hd(query.wheres).params == [{book_id, {1, :book_id}}]
    end
  end

  describe "by_category_id/1" do
    test "creates a query filtered by category_id" do
      category_id = 123
      query = EnvelopeQuery.by_category_id(category_id)

      assert query.from.source == {"envelopes", Envelope}
      assert length(query.wheres) == 1

      [where_clause] = query.wheres
      assert where_clause.params == [{category_id, {0, :category_id}}]
    end
  end

  describe "by_category_id/2" do
    test "adds category_id filter to existing query" do
      base_query = from(e in Envelope, where: e.name == "Test")
      query = EnvelopeQuery.by_category_id(base_query, 456)

      assert length(query.wheres) == 2
      param_values = Enum.flat_map(query.wheres, & &1.params)
      assert {456, {0, :category_id}} in param_values
    end
  end

  describe "order_by_position/0" do
    test "creates a query ordered by position ascending" do
      query = EnvelopeQuery.order_by_position()

      assert query.from.source == {"envelopes", Envelope}
      assert length(query.order_bys) == 1

      [order_by] = query.order_bys
      assert order_by.expr == [asc: {{:., [], [{:&, [], [0]}, :position]}, [], []}]
    end
  end

  describe "order_by_position/1" do
    test "adds position ordering to existing query" do
      base_query = from(e in Envelope, where: e.category_id == 1)
      query = EnvelopeQuery.order_by_position(base_query)

      assert length(query.order_bys) == 1
      assert length(query.wheres) == 1

      [order_by] = query.order_bys
      assert order_by.expr == [asc: {{:., [], [{:&, [], [0]}, :position]}, [], []}]
    end
  end

  describe "limit/1" do
    test "creates a query with limit" do
      query = EnvelopeQuery.limit(5)

      assert query.from.source == {"envelopes", Envelope}
      assert query.limit.expr == {:^, [], [0]}
      assert query.limit.params == [{5, :integer}]
    end
  end

  describe "limit/2" do
    test "adds limit to existing query" do
      base_query = from(e in Envelope, where: e.category_id == 1)
      query = EnvelopeQuery.limit(base_query, 10)

      assert query.limit.expr == {:^, [], [0]}
      assert query.limit.params == [{10, :integer}]
      assert length(query.wheres) == 1
    end
  end

  describe "select_position/0" do
    test "creates a query selecting only position" do
      query = EnvelopeQuery.select_position()

      assert query.from.source == {"envelopes", Envelope}
      assert query.select.expr == {{:., [], [{:&, [], [0]}, :position]}, [], []}
    end
  end

  describe "select_position/1" do
    test "adds position selection to existing query" do
      base_query = from(e in Envelope, where: e.category_id == 1)
      query = EnvelopeQuery.select_position(base_query)

      assert query.select.expr == {{:., [], [{:&, [], [0]}, :position]}, [], []}
      assert length(query.wheres) == 1
    end
  end
end

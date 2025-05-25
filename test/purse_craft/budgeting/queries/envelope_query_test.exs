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
end

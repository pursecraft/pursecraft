defmodule PurseCraft.Accounting.Queries.AccountQueryTest do
  use PurseCraft.DataCase, async: true

  import Ecto.Query

  alias PurseCraft.Accounting.Queries.AccountQuery
  alias PurseCraft.Accounting.Schemas.Account

  describe "by_book_id/1" do
    test "creates a query filtered by book_id" do
      book_id = 123
      query = AccountQuery.by_book_id(book_id)

      assert query.from.source == {"accounts", Account}
      assert length(query.wheres) == 1
      assert hd(query.wheres).params == [{book_id, {0, :book_id}}]
    end
  end

  describe "by_book_id/2" do
    test "adds book_id filter to existing query" do
      base_query = from(a in Account, where: a.name == "Test")
      book_id = 456

      query = AccountQuery.by_book_id(base_query, book_id)

      assert query.from.source == {"accounts", Account}
      assert length(query.wheres) == 2

      param_values = Enum.flat_map(query.wheres, & &1.params)
      assert {book_id, {0, :book_id}} in param_values
    end

    test "preserves other query attributes" do
      base_query =
        from(a in Account,
          where: a.name == "Test",
          order_by: a.inserted_at,
          limit: 10
        )

      query = AccountQuery.by_book_id(base_query, 789)

      assert length(query.wheres) == 2
      assert length(query.order_bys) == 1
      assert query.limit.expr == 10
    end
  end

  describe "order_by_position/0" do
    test "creates a query ordered by position in ascending order" do
      query = AccountQuery.order_by_position()

      assert query.from.source == {"accounts", Account}
      assert length(query.order_bys) == 1

      [order_by] = query.order_bys
      assert order_by.expr == [asc: {{:., [], [{:&, [], [0]}, :position]}, [], []}]
    end
  end

  describe "order_by_position/1" do
    test "adds position ordering to existing query" do
      base_query = from(a in Account, where: a.book_id == 1)
      query = AccountQuery.order_by_position(base_query)

      assert length(query.order_bys) == 1
      [order_by] = query.order_bys
      assert order_by.expr == [asc: {{:., [], [{:&, [], [0]}, :position]}, [], []}]
    end

    test "preserves existing filters" do
      base_query = from(a in Account, where: a.book_id == 1, where: a.account_type == "checking")
      query = AccountQuery.order_by_position(base_query)

      assert length(query.wheres) == 2
      assert length(query.order_bys) == 1
    end
  end

  describe "limit/1" do
    test "creates a query with limit" do
      count = 5
      query = AccountQuery.limit(count)

      assert query.from.source == {"accounts", Account}
      assert query.limit.expr == {:^, [], [0]}
      assert query.limit.params == [{5, :integer}]
    end
  end

  describe "limit/2" do
    test "adds limit to existing query" do
      base_query = from(a in Account, where: a.book_id == 1)
      count = 3

      query = AccountQuery.limit(base_query, count)

      assert length(query.wheres) == 1
      assert query.limit.expr == {:^, [], [0]}
      assert query.limit.params == [{3, :integer}]
    end

    test "overwrites existing limit" do
      base_query = from(a in Account, limit: 10)
      query = AccountQuery.limit(base_query, 5)

      assert query.limit.expr == {:^, [], [0]}
      assert query.limit.params == [{5, :integer}]
    end
  end

  describe "select_position/0" do
    test "creates a query that selects only the position field" do
      query = AccountQuery.select_position()

      assert query.from.source == {"accounts", Account}
      assert query.select.expr == {{:., [], [{:&, [], [0]}, :position]}, [], []}
    end
  end

  describe "select_position/1" do
    test "adds position selection to existing query" do
      base_query = from(a in Account, where: a.book_id == 1)
      query = AccountQuery.select_position(base_query)

      assert length(query.wheres) == 1
      assert query.select.expr == {{:., [], [{:&, [], [0]}, :position]}, [], []}
    end

    test "adds position selection to query without existing select" do
      base_query = from(a in Account, where: a.book_id == 1, order_by: a.position)
      query = AccountQuery.select_position(base_query)

      assert length(query.wheres) == 1
      assert length(query.order_bys) == 1
      assert query.select.expr == {{:., [], [{:&, [], [0]}, :position]}, [], []}
    end
  end

  describe "by_external_id/1" do
    test "creates a query filtered by external_id" do
      external_id = "123e4567-e89b-12d3-a456-426614174000"
      query = AccountQuery.by_external_id(external_id)

      assert query.from.source == {"accounts", Account}
      assert length(query.wheres) == 1
      assert hd(query.wheres).params == [{external_id, {0, :external_id}}]
    end
  end

  describe "by_external_id/2" do
    test "adds external_id filter to existing query" do
      base_query = from(a in Account, where: a.book_id == 1)
      external_id = "123e4567-e89b-12d3-a456-426614174000"

      query = AccountQuery.by_external_id(base_query, external_id)

      assert query.from.source == {"accounts", Account}
      assert length(query.wheres) == 2

      param_values = Enum.flat_map(query.wheres, & &1.params)
      assert {external_id, {0, :external_id}} in param_values
    end

    test "preserves other query attributes" do
      base_query =
        from(a in Account,
          where: a.book_id == 1,
          order_by: a.position,
          limit: 5
        )

      external_id = "123e4567-e89b-12d3-a456-426614174000"
      query = AccountQuery.by_external_id(base_query, external_id)

      assert length(query.wheres) == 2
      assert length(query.order_bys) == 1
      assert query.limit.expr == 5
    end
  end

  describe "active/0" do
    test "creates a query for active (non-closed) accounts" do
      query = AccountQuery.active()

      assert query.from.source == {"accounts", Account}
      assert length(query.wheres) == 1

      [where_clause] = query.wheres
      assert where_clause.expr == {:is_nil, [], [{{:., [], [{:&, [], [0]}, :closed_at]}, [], []}]}
    end
  end

  describe "active/1" do
    test "adds active filter to existing query" do
      base_query = from(a in Account, where: a.book_id == 1)
      query = AccountQuery.active(base_query)

      assert length(query.wheres) == 2

      where_exprs = Enum.map(query.wheres, & &1.expr)
      assert {:is_nil, [], [{{:., [], [{:&, [], [0]}, :closed_at]}, [], []}]} in where_exprs
    end

    test "preserves other query attributes" do
      base_query =
        from(a in Account,
          where: a.book_id == 1,
          where: a.account_type == "checking",
          order_by: a.position,
          limit: 10
        )

      query = AccountQuery.active(base_query)

      assert length(query.wheres) == 3
      assert length(query.order_bys) == 1
      assert query.limit.expr == 10
    end

    test "combines with by_external_id query" do
      external_id = "123e4567-e89b-12d3-a456-426614174000"

      query =
        Account
        |> AccountQuery.by_book_id(1)
        |> AccountQuery.by_external_id(external_id)
        |> AccountQuery.active()

      assert length(query.wheres) == 3

      where_exprs = Enum.map(query.wheres, & &1.expr)
      assert {:is_nil, [], [{{:., [], [{:&, [], [0]}, :closed_at]}, [], []}]} in where_exprs

      param_values = Enum.flat_map(query.wheres, & &1.params)
      assert {1, {0, :book_id}} in param_values
      assert {external_id, {0, :external_id}} in param_values
    end
  end
end
